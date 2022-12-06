/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

interface IPancakeSwapPair {
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

interface IPancakeSwapRouter{
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

interface IPancakeSwapFactory {
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

    //Mainnet
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); 

    //testnet usdc 
    // IERC20 USDT = IERC20(0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C); 

    IPancakeSwapRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public currentIndex;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 12;
    uint256 public minPeriod = 3600;
    uint256 public minDistribution = 1 * (10 ** 6);

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); 
        _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IPancakeSwapRouter(_router)
        : IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
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

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyToken returns (bool success){
        return IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = USDT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(USDT);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = USDT.balanceOf(address(this)).sub(balanceBefore);

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
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            USDT.transfer(shareholder, amount);
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

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SDOGE is IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Santa Doge";
    string private constant _symbol = "SDOGE";
    uint8 private constant _decimals = 6;

    uint256 public buyLiquidityFee = 10;
    uint256 public buyMarketingFee = 20;
    uint256 public buyDeveloperFee = 20;
    uint256 public buyRewardsFee = 10;

    uint256 public sellLiquidityFee = 10;
    uint256 public sellMarketingFee = 20;
    uint256 public sellDeveloperFee = 20;
    uint256 public sellRewardsFee = 10;

    uint256 public AmountLiquidityFee;
    uint256 public AmountMarketingFee;
    uint256 public AmountDeveloperFee;
    uint256 public AmountRewardsFee;

    uint256 private constant feeDenominator = 1000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;  

    address public _marketingWalletAddress = 0x7e70340e3438eB90884744Bc1035DcAC1b898BDc;
    address public _developerWalletAddress = 0x361aD07081dFd31A87F497a976Ed34A960D0e022;
    address public _liquidityReciever;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant ZeroWallet = 0x0000000000000000000000000000000000000000;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    mapping(address => bool) public isDividendExempt;
    mapping (address => bool) public blacklisted;

    uint256 public _totalSupply = 1_000_000_000 * (10 ** _decimals);

    uint256 public MaxWalletLimit = _totalSupply.mul(10).div(feeDenominator);  //1%
    uint256 public MaxTxLimit = _totalSupply.mul(5).div(feeDenominator);  //0.5%

    uint256 public swapTokensAtAmount = 10000 * (10 ** _decimals); //0.5%

    bool public EnableTransactionLimit = true;
    bool public checkWalletLimit = true;

    bool public _enableSwap = true; 

    bool public initalDistribution;
    bool public triggered;
    uint public launchTime;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }
  
    DividendDistributor distributor;
    address public SDDividendReceiver;

    uint256 distributorGas = 500000;
    
    address public pair;
    IPancakeSwapPair public pairContract;
    IPancakeSwapRouter public router;

    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable() {

        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

        router = IPancakeSwapRouter(_router); 

        pair = IPancakeSwapFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = ~uint256(0);

        pairContract = IPancakeSwapPair(pair);
        automatedMarketMakerPairs[pair] = true;
        
        _liquidityReciever = msg.sender;

        distributor = new DividendDistributor(_router);
        SDDividendReceiver = address(distributor);

        isDividendExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadWallet] = true;
        isDividendExempt[ZeroWallet] = true;
        
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
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

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(_balances[deadWallet]).sub(_balances[ZeroWallet]);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }    

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isExcludedFromFees[_addr];
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
    ) external validRecipient(to) override returns (bool) {
        
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0,"Error: Invalid Amount!");

        require(!blacklisted[sender] && !blacklisted[recipient],"Error: Blacklist Bots/Contracts not Allowed!!");
        require(initalDistribution || isOwner() ,"Trade is Currently Paused!!");
        
        if((block.timestamp > launchTime + 15 minutes) && !triggered && (launchTime != 0) ){
            MaxTxLimit =  _totalSupply.mul(15).div(feeDenominator);     //1.5%
            MaxWalletLimit = _totalSupply.mul(15).div(feeDenominator);    //1.5%
            triggered = true;
        }

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTransactionLimit) {
            require(amount <= MaxTxLimit, "Error: Transfer amount exceeds the maxTxAmount.");
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
            require(balanceOf(recipient).add(AmountReceived) <= MaxWalletLimit,"Error: Transfer Amount exceeds Wallet Limit.");
        }

        _balances[recipient] = _balances[recipient].add(AmountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender,recipient,AmountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {

        uint256 feeAmount;
        uint LFEE;
        uint MFEE;
        uint RFEE;
        uint DFEE;
        
        if(automatedMarketMakerPairs[sender]){

            LFEE = amount.mul(buyLiquidityFee).div(feeDenominator);
            AmountLiquidityFee += LFEE;
            MFEE = amount.mul(buyMarketingFee).div(feeDenominator);
            AmountMarketingFee += MFEE;
            RFEE = amount.mul(buyRewardsFee).div(feeDenominator);
            AmountRewardsFee += RFEE;
            DFEE = amount.mul(buyDeveloperFee).div(feeDenominator);
            AmountDeveloperFee += DFEE;

            feeAmount = LFEE.add(MFEE).add(RFEE).add(DFEE);
        }
        else if(automatedMarketMakerPairs[recipient]){

            LFEE = amount.mul(sellLiquidityFee).div(feeDenominator);
            AmountLiquidityFee += LFEE;
            MFEE = amount.mul(sellMarketingFee).div(feeDenominator);
            AmountMarketingFee += MFEE;
            RFEE = amount.mul(sellRewardsFee).div(feeDenominator);
            AmountRewardsFee += RFEE;
            DFEE = amount.mul(sellDeveloperFee).div(feeDenominator);
            AmountDeveloperFee += DFEE;

            feeAmount = LFEE.add(MFEE).add(RFEE).add(DFEE);
    
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function manualSwap() public onlyOwner swapping { 
        if(AmountLiquidityFee > 0) swapForLiquidity(AmountLiquidityFee); 
        if(AmountMarketingFee > 0) swapForMarketing(AmountMarketingFee);
        if(AmountDeveloperFee > 0) swapForDevelopers(AmountDeveloperFee);
        if(AmountRewardsFee > 0) swapAndSendDivident(AmountRewardsFee);
    }

    function swapBack() internal swapping {
        if(AmountLiquidityFee > 0) swapForLiquidity(AmountLiquidityFee); 
        if(AmountMarketingFee > 0) swapForMarketing(AmountMarketingFee);
        if(AmountDeveloperFee > 0) swapForDevelopers(AmountDeveloperFee);
        if(AmountRewardsFee > 0) swapAndSendDivident(AmountRewardsFee);
    }

    function swapAndSendDivident(uint256 _tokens) private {
        uint initialBalance = address(this).balance;
        swapTokensForEth(_tokens);
        uint ReceivedBalance = address(this).balance.sub(initialBalance);
        AmountRewardsFee = AmountRewardsFee.sub(_tokens);
        try distributor.deposit { value: ReceivedBalance } () {} catch {}  
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
            _enableSwap && 
            !inSwap && 
            canSwap &&
            !automatedMarketMakerPairs[msg.sender];
    }

    function setAutoSwapBack(bool _flag) external onlyOwner {
        if(_flag) {
            _enableSwap = _flag;
        } else {
            _enableSwap = _flag;
        }
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

    function setBuyFee(
            uint _newLp,
            uint _newMarketing,
            uint _newReward,
            uint _newDeveloper
        ) public onlyOwner {
      
        buyLiquidityFee = _newLp;
        buyMarketingFee = _newMarketing;
        buyRewardsFee = _newReward;
        buyDeveloperFee = _newDeveloper;
    }

    function setSellFee(
            uint _newLp,
            uint _newMarketing,
            uint _newReward,
            uint _newDeveloper
        ) public onlyOwner {

        sellLiquidityFee = _newLp;
        sellMarketingFee = _newMarketing;
        sellRewardsFee = _newReward;
        sellDeveloperFee = _newDeveloper;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && !automatedMarketMakerPairs[holder]);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function blacklistBot(address _adr,bool _status) public onlyOwner {
        blacklisted[_adr] = _status;
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner returns (bool success){
        return IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueDToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner returns (bool success) {
        return distributor.rescueToken(tokenAddress, _receiver,tokens);
    }

    function setFeeReceivers(address _marketing,address _liquidity,address _developer) public onlyOwner {
        _marketingWalletAddress = _marketing;
        _liquidityReciever = _liquidity;
        _developerWalletAddress = _developer;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    function enableDisableTxLimit(bool _status) public onlyOwner {
        EnableTransactionLimit = _status;
    }

    function enableDisableWalletLimit(bool _status) public onlyOwner {
        checkWalletLimit = _status;
    }

    function setMaxWalletLimit(uint _value) public onlyOwner {
        MaxWalletLimit = _value;
    }

    function setMaxTxLimit(uint _value) public onlyOwner {
        MaxTxLimit = _value; 
    }

    function setLP(address _address) external onlyOwner {
        pair = _address;
    }

    function setAutomaticPairMarket(address _addr,bool _status) public onlyOwner {
        if(_status) {
            require(!automatedMarketMakerPairs[_addr],"Pair Already Set!!");
        }
        automatedMarketMakerPairs[_addr] = _status;
        isDividendExempt[_addr] = true;
        isWalletLimitExempt[_addr] = true;
    }

    function setWhitelistFee(address _addr,bool _status) external onlyOwner {
        require(_isExcludedFromFees[_addr] != _status, "Error: Not changed");
        _isExcludedFromFees[_addr] = _status;
    }

    function setEdTxLimit(address _addr,bool _status) external onlyOwner {
        isTxLimitExempt[_addr] = _status;
    }

    function setEdWalletLimit(address _addr,bool _status) external onlyOwner {
        isWalletLimitExempt[_addr] = _status;
    }

    function setMinSwapAmount(uint _value) external onlyOwner {
        swapTokensAtAmount = _value;
    }

    function openTrade(bool _status, bool _s) public onlyOwner {
        initalDistribution = _status;
        if(_s){
            launchTime = block.timestamp;
        }
    }

    function swapForMarketing(uint _tokens) private {
        uint initalBalance = address(this).balance;
        swapTokensForEth(_tokens);
        uint recieveBalance = address(this).balance.sub(initalBalance);
        AmountMarketingFee = AmountMarketingFee.sub(_tokens);
        payable(_marketingWalletAddress).transfer(recieveBalance);
    }

    function swapForDevelopers(uint _tokens) private {
        uint initalBalance = address(this).balance;
        swapTokensForEth(_tokens);
        uint recieveBalance = address(this).balance.sub(initalBalance);
        AmountDeveloperFee = AmountDeveloperFee.sub(_tokens);
        payable(_developerWalletAddress).transfer(recieveBalance);
    }

    function swapForLiquidity(uint _tokens) private {
        uint half = AmountLiquidityFee.div(2);
        uint otherhalf = AmountLiquidityFee.sub(half);
        uint initalBalance = address(this).balance;
        swapTokensForEth(half);
        uint recieveBalance = address(this).balance.sub(initalBalance);
        AmountLiquidityFee = AmountLiquidityFee.sub(_tokens);
        addLiquidity(otherhalf,recieveBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);
        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityReciever,
            block.timestamp
        );

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

    /* AirDrop begins*/

    function airDrop(address[] calldata _adr, uint[] calldata _tokens) public onlyOwner {
        require(_adr.length == _tokens.length,"Length Mismatch!!");
        uint Subtokens;
        address account = msg.sender;
        for(uint i=0; i < _tokens.length; i++){
            Subtokens += _tokens[i];
        }
        require(balanceOf(account) >= Subtokens,"ERROR: Insufficient Balance!!");
        _balances[account] = _balances[account].sub(Subtokens);
        for (uint j=0; j < _adr.length; j++) {
            _balances[_adr[j]] = _balances[_adr[j]].add(_tokens[j]);
            emit Transfer(account,_adr[j],_tokens[j]);
        } 
    }

}