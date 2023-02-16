/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT

/*

Website: https://reward-face.com
Twitter: https://twitter.com/RewardFace
Telegram: https://t.me/RewardFace

*/

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface WrappedETH {
    function deposit() external payable;
}

interface IDEXRouter{
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

interface IDEXFactory{
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);
		function getPair(address tokenA, address tokenB) external view returns (address pair);
		function createPair(address tokenA, address tokenB) external returns (address pair);
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
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimReward(address shareHolder) external;
    function getUnpaidEarning(address shareholder) external view returns (uint256);
}

contract BTCDividend is IDividendDistributor {     //LENNY FACE
    
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 reserved;
    }
    mapping (address => Share) public shares;
    
    IERC20 RewardToken = IERC20(0xDadb4aE5B5D3099Dd1f586f990B845F2404A1c4c); // LENNY CA

    IDEXRouter router;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 private totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public totalReserved;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 16;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RewardToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = calEarning(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].reserved += amount;
            totalReserved += amount;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarning(address shareholder) public override view returns (uint256) {
        uint calReward = calEarning(shareholder);
        uint reservedReward = shares[shareholder].reserved;
        return calReward.add(reservedReward);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyToken {
        IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueFunds(address _receiver) external onlyToken {
        payable(_receiver).transfer(address(this).balance);
    }

    function claimDividend() external {
        address user = msg.sender;
        transferShares(user);
    }

    function claimReward(address shareHolder) external override onlyToken {
        transferShares(shareHolder);
    }

    function transferShares(address user) internal {
        distributeDividend(user);
        uint subtotal = shares[user].reserved;
        if(subtotal > 0) {
            shares[user].reserved = 0;
            totalReserved = totalReserved.sub(subtotal);
            RewardToken.transfer(user, subtotal);
        }
    }

    function calEarning(address shareholder) internal view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

}

contract ETHDividend is IDividendDistributor {     //ETH
    
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 reserved;
    }
    mapping (address => Share) public shares;
    
    IERC20 RewardToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH CA

    IDEXRouter router;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 private totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public totalReserved;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 26;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RewardToken.balanceOf(address(this));
        WrappedETH(address(RewardToken)).deposit{value: msg.value}();
        uint256 amount = RewardToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = calEarning(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].reserved += amount;
            totalReserved += amount;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarning(address shareholder) public override view returns (uint256) {
        uint calReward = calEarning(shareholder);
        uint reservedReward = shares[shareholder].reserved;
        return calReward.add(reservedReward);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyToken {
        IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueFunds(address _receiver) external onlyToken {
        payable(_receiver).transfer(address(this).balance);
    }

    function claimDividend() external {
        address user = msg.sender;
        transferShares(user);
    }

    function claimReward(address shareHolder) external override onlyToken {
        transferShares(shareHolder);
    }

    function transferShares(address user) internal {
        distributeDividend(user);
        uint subtotal = shares[user].reserved;
        if(subtotal > 0) {
            shares[user].reserved = 0;
            totalReserved = totalReserved.sub(subtotal);
            RewardToken.transfer(user, subtotal);
        }
    }

    function calEarning(address shareholder) internal view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

}

contract REFACE is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "Reward Face";
    string private _symbol = "REFACE";
    uint8 private _decimals = 18;

    uint256 public buyMarketingFee = 200;
    uint256 public buyLennyFee = 10;
    uint256 public buyWETHFee = 10;

    uint256 public sellMarketingFee = 200;
    uint256 public sellLennyFee = 10;
    uint256 public sellWETHFee = 10;

    uint256 public totalBuy;
    uint256 public totalSell;

    uint256 public feeDenominator = 1000;

    address public _marketingWalletAddress = 0xfBb699a91168B474c9c14A883aD5AcA50aff6118;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant ZeroWallet = 0x0000000000000000000000000000000000000000;

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping(address => bool) public isBTCDivExempt;
    mapping(address => bool) public isETHDivExempt;
    mapping(address => bool) public blacklist;

    uint256 public _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public swapTokensAtAmount = _totalSupply.mul(5).div(1e5); //0.05%

    uint256 public swapProtection = _totalSupply.mul(1).div(100);

    uint256 public MaxWalletLimit = _totalSupply.mul(20).div(feeDenominator);  //2%
    uint256 public MaxTxLimit = _totalSupply.mul(20).div(feeDenominator);      //2%

    bool public EnableTransactionLimit = true;
    bool public checkWalletLimit = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;  

    bool public _autoSwapBack = true;
    bool public ActiveTrading = false;

    BTCDividend public lennydividend;
    ETHDividend public ethdividend;
    address public rewardController;
    IDEXRouter public router;

    bool inSwap = false;
    
    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    modifier onlyRewardController {
        require(msg.sender == rewardController);
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        address pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = ~uint256(0);

        lennydividend = new BTCDividend(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ethdividend = new ETHDividend(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardController = msg.sender;
        automatedMarketMakerPairs[pair] = true;

        isETHDivExempt[msg.sender] = true;
        isETHDivExempt[pair] = true;
        isETHDivExempt[address(this)] = true;
        isETHDivExempt[deadWallet] = true;
        isETHDivExempt[ZeroWallet] = true;

        isBTCDivExempt[msg.sender] = true;
        isBTCDivExempt[pair] = true;
        isBTCDivExempt[address(this)] = true;
        isBTCDivExempt[deadWallet] = true;
        isBTCDivExempt[ZeroWallet] = true;
        
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        totalBuy = buyMarketingFee.add(buyLennyFee).add(buyWETHFee);
        totalSell = sellMarketingFee.add(sellLennyFee).add(sellWETHFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(_balances[deadWallet]).sub(_balances[ZeroWallet]);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isExcludedFromFees[_addr];
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender,spender,value);
        return true;
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

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        
        if (_allowances[from][msg.sender] != ~uint256(0)) {
            _allowances[from][msg.sender] = _allowances[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

        if(!ActiveTrading) {
           require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient],"Error: Trading Paused!"); 
        }

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTransactionLimit) {
            require(amount <= MaxTxLimit, "Transfer amount exceeds the maxTxAmount.");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        
        _balances[sender] = _balances[sender].sub(amount);
        
        uint256 AmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;

        if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
            require(balanceOf(recipient).add(AmountReceived) <= MaxWalletLimit);
        }
        
        _balances[recipient] = _balances[recipient].add(AmountReceived);

        if(!isBTCDivExempt[sender]){ try lennydividend.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isBTCDivExempt[recipient]){ try lennydividend.setShare(recipient, balanceOf(recipient)) {} catch {} }

        if(!isETHDivExempt[sender]){ try ethdividend.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isETHDivExempt[recipient]){ try ethdividend.setShare(recipient, balanceOf(recipient)) {} catch {} }

        emit Transfer(sender,recipient,AmountReceived);

        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal  returns (uint256) {

        uint256 feeAmount;
        
        if(automatedMarketMakerPairs[sender]){
            feeAmount = amount.mul(totalBuy).div(feeDenominator);
        }
        else if(automatedMarketMakerPairs[recipient]){
            feeAmount = amount.mul(totalSell).div(feeDenominator);
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        uint totalShares = totalBuy.add(totalSell);
        if(totalShares == 0) return;

        if(contractBalance > swapProtection) {
            contractBalance = swapProtection;
        }

        uint _mshares = buyMarketingFee.add(sellMarketingFee);
        uint _btcshares = buyLennyFee.add(sellLennyFee);
        // uint _ethshares = buyWETHFee.add(sellWETHFee);
        uint initalBalance = address(this).balance;
        swapTokensForEth(contractBalance);
        uint recievedBalance = address(this).balance.sub(initalBalance);

        uint MarketingShares = recievedBalance.mul(_mshares).div(totalShares);
        uint BTCdividendShares = recievedBalance.mul(_btcshares).div(totalShares);
        uint ETHDividendShares = recievedBalance.sub(MarketingShares).sub(BTCdividendShares);
        if(MarketingShares > 0) {
            payable(_marketingWalletAddress).transfer(MarketingShares);
        }
        if(BTCdividendShares > 0) {
            try lennydividend.deposit { value: BTCdividendShares } () {} catch {}             
        }
        if(ETHDividendShares > 0) {
            try ethdividend.deposit { value: ETHDividendShares } () {} catch {}    
        }
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            return false;
        }        
        else{
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        return
            canSwap &&
            _autoSwapBack &&
            !inSwap &&
            !automatedMarketMakerPairs[msg.sender]; 
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowances[msg.sender][spender] = _allowances[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function manualSwap() external onlyOwner {
        if(inSwap) {
            revert("Already in Swap");
        }
        swapBack();
    }

    function enableDisableTxLimit(bool _status) external onlyOwner {
        EnableTransactionLimit = _status;
    }

    function enableDisableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function enableTrading(bool _status) external onlyOwner {
        ActiveTrading = _status;
    }

    function setAutoSwapBack(bool _flag) external onlyOwner {
        _autoSwapBack = _flag;
    }

    function setFeeReceivers(address _marketing) external onlyRewardController {
        _marketingWalletAddress = _marketing;
    }

    function setMaxWalletLimit(uint _value) external onlyOwner {
        MaxWalletLimit = _value;
    }

    function setMaxTxLimit(uint _value) external onlyOwner {
        MaxTxLimit = _value; 
    }

    function setBuyFee(
            uint _newMarketing,
            uint _newLenny,
            uint _newWETH
        ) external onlyOwner {
        buyMarketingFee = _newMarketing;
        buyLennyFee = _newLenny;
        buyWETHFee = _newWETH;
        totalBuy = buyMarketingFee.add(buyLennyFee).add(buyWETHFee);
    }

    function setSellFee(
            uint _newMarketing,
            uint _newLenny,
            uint _newWETH
        ) external onlyOwner {
        sellMarketingFee = _newMarketing;
        sellLennyFee = _newLenny;
        sellWETHFee = _newWETH;
        totalSell = sellMarketingFee.add(sellLennyFee).add(sellWETHFee);
    }

    function setAutomaticPairMarket(address _addr,bool _status) external onlyOwner {
        if(_status) {
            require(!automatedMarketMakerPairs[_addr],"Pair Already Set!!");
        }
        automatedMarketMakerPairs[_addr] = _status;
        isWalletLimitExempt[_addr] = true;
        isETHDivExempt[_addr] = true;
        isBTCDivExempt[_addr] = true;
    }

    function excludeLennyDividend(address _addr,bool _status) external onlyOwner {
        if(_status) {
            lennydividend.setShare(_addr,0);
        }
        else {
            lennydividend.setShare(_addr,balanceOf(_addr));
        }
        isBTCDivExempt[_addr] = _status;
    } 

    function excludeEthDividend(address _addr,bool _status) external onlyOwner {
        if(_status) {
            ethdividend.setShare(_addr,0);
        }
        else {
            ethdividend.setShare(_addr,balanceOf(_addr));
        }
        isETHDivExempt[_addr] = _status;
    }   

    function enableFee(address _addr,bool _status) external onlyOwner {
        _isExcludedFromFees[_addr] = _status;
    }

    function enableTxLimit(address _addr,bool _status) external onlyOwner {
        isTxLimitExempt[_addr] = _status;
    }

    function enableWalletLimit(address _addr,bool _status) external onlyOwner {
        isWalletLimitExempt[_addr] = _status;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        blacklist[_botAddress] = _flag;    
    }

    function setMinSwapAmount(uint _value) external onlyOwner {
        swapTokensAtAmount = _value;
    }  

    function setSwapProtection(uint _value) external onlyOwner {
        swapProtection = _value;
    }

    //claimers

    function lennyReward() external {
        lennydividend.claimReward(msg.sender);
    }

    function ethReward() external {
        ethdividend.claimReward(msg.sender);
    }

    //Rescuers

    function getLennyRewardInfo(address _receiver) external view returns (uint) {
        return lennydividend.getUnpaidEarning(_receiver);
    }

    function getETHRewardInfo(address _receiver) external view returns (uint) {
        return ethdividend.getUnpaidEarning(_receiver);
    }

    function lennyRescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyRewardController {
        lennydividend.rescueToken(tokenAddress,_receiver,tokens);
    }

    function lennyRescueFunds(address _receiver) external onlyRewardController {
        lennydividend.rescueFunds(_receiver);
    }

    function ethRescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyRewardController {
        ethdividend.rescueToken(tokenAddress,_receiver,tokens);
    }

    function ethRescueFunds(address _receiver) external onlyRewardController {
        ethdividend.rescueFunds(_receiver);
    }

    function rescueFunds() external onlyRewardController {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueToken(address _token, uint _value) external onlyRewardController {
        IERC20(_token).transfer(msg.sender,_value);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
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
   
    receive() external payable {}

}