/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

/*


     ██████   ██████  ██      ██████  ███████ ███    ██     ██████  ███████ ████████ ██████  ██ ███████ ██    ██ ███████ ██████      ██    ██ ██████  
    ██       ██    ██ ██      ██   ██ ██      ████   ██     ██   ██ ██         ██    ██   ██ ██ ██      ██    ██ ██      ██   ██     ██    ██      ██ 
    ██   ███ ██    ██ ██      ██   ██ █████   ██ ██  ██     ██████  █████      ██    ██████  ██ █████   ██    ██ █████   ██████      ██    ██  █████  
    ██    ██ ██    ██ ██      ██   ██ ██      ██  ██ ██     ██   ██ ██         ██    ██   ██ ██ ██       ██  ██  ██      ██   ██      ██  ██  ██      
     ██████   ██████  ███████ ██████  ███████ ██   ████     ██   ██ ███████    ██    ██   ██ ██ ███████   ████   ███████ ██   ██       ████   ███████ 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

This is THE REAL 02 of Golden Retriever Token, Gold Retriever. Two things that have held true since the beginning of time. The first, dogs have given us unconditional love. 
The perfect example is The Golden Retriever. If you don’t believe in God go play with one and you will. 
The second is that Gold is the only real money.  Put it on the blockchain it’s unstoppable. I have given you both. 
A token that Rewards in real gold and a token that harnesses the financial freedom of blockchain all while giving back to the beings that never stopped loving us, dogs. 
This contract will be locked for quite some time. 
Use it well and save your gold, you will need it as the fiat markets crumble which is NOW.  
The gold rewards you receive are redeemable for real physical gold. 



https://www.thegoldenretrievertoken.com
https://t.me/GLDN_Retriever
https://twitter.com/0xGoldRetriever

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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
    IERC20 PAX = IERC20(0x45804880De22913dAFE09f4980848ECE6EcbAf78); 

    //Testnet 
    //IERC20 PAX = IERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);  //DAI TOKEN

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

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

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
        uint256 balanceBefore = PAX.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(PAX);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = PAX.balanceOf(address(this)).sub(balanceBefore);

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
            PAX.transfer(shareholder, amount);
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

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
}

contract GoldenRetrieverV2 is ERC20Detailed, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;


    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public buyLiquidityFee = 0;
    uint256 public buyMarketingFee = 0;
    uint256 public buyRewardsFee = 0;

    uint256 public sellLiquidityFee = 40;
    uint256 public sellMarketingFee = 0;
    uint256 public sellRewardsFee = 40;

    uint256 public AmountLiquidityFee;
    uint256 public AmountMarketingFee;
    uint256 public AmountRewardsFee;

    uint256 public feeDenominator = 1000;

    address public _marketingWalletAddress = 0x76b61a1AFe8711F431d3d6F770E8fE7e7004E871;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant ZeroWallet = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public blacklist;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public isDividendExempt;
    mapping (address => bool) private allowTransfer;

    uint256 public constant DECIMALS = 18;

    uint256 public _totalSupply = 10_500_000 * (10 ** DECIMALS);
    uint256 public swapTokensAtAmount = _totalSupply.mul(5).div(1e5); //0.05%

    uint256 public MaxWalletLimit = _totalSupply.mul(30).div(feeDenominator);  //3%
    uint256 public MaxTxLimit = _totalSupply.mul(15).div(feeDenominator);    //1.5%

    bool public EnableTransactionLimit = true;
    bool public checkWalletLimit = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;  

    bool public _autoAddLiquidity = true;
    bool public _autoSwapBack = true;
    bool public ClaimableOnly = true;  
    bool public initalDistribution;
  
    DividendDistributor distributor;
    address public GLDNRTVRDividendReceiver;

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

    constructor() ERC20Detailed("Gold Retriever", "GLDN", uint8(DECIMALS)) Ownable() {

        router = IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ); 

        pair = IPancakeSwapFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = uint256(-1);

        pairContract = IPancakeSwapPair(pair);
        automatedMarketMakerPairs[pair] = true;

        distributor = new DividendDistributor(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );

        GLDNRTVRDividendReceiver = address(distributor);

        isDividendExempt[owner()] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadWallet] = true;
        isDividendExempt[ZeroWallet] = true;
        
        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        _balances[owner()] = _totalSupply;
        emit Transfer(address(0x0), owner(), _totalSupply);
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
        
        if (_allowances[from][msg.sender] != uint256(-1)) {
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

        require(initalDistribution || allowTransfer[msg.sender] || isOwner() ,"Trade is Currently Paused!!");

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTransactionLimit) {
            require(amount <= MaxTxLimit, "Transfer amount exceeds the maxTxAmount.");
        }


        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldAddLiquidity()) {
            addLiquidity();
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        
        _balances[sender] = _balances[sender].sub(amount);
        
        uint256 AmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(AmountReceived);

        if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
            require(balanceOf(recipient).add(AmountReceived) <= MaxWalletLimit);
        }

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }

        if(!ClaimableOnly)  try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender,recipient,AmountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal  returns (uint256) {

        uint256 feeAmount;
        uint LFEE;
        uint MFEE;
        uint RFEE;
        
        if(automatedMarketMakerPairs[sender]){

            LFEE = amount.mul(buyLiquidityFee).div(feeDenominator);
            AmountLiquidityFee += LFEE;
            MFEE = amount.mul(buyMarketingFee).div(feeDenominator);
            AmountMarketingFee += MFEE;
            RFEE = amount.mul(buyRewardsFee).div(feeDenominator);
            AmountRewardsFee += RFEE;

            feeAmount = LFEE.add(MFEE).add(RFEE);
        }
        else if(automatedMarketMakerPairs[recipient]){

            LFEE = amount.mul(sellLiquidityFee).div(feeDenominator);
            AmountLiquidityFee += LFEE;
            MFEE = amount.mul(sellMarketingFee).div(feeDenominator);
            AmountMarketingFee += MFEE;
            RFEE = amount.mul(sellRewardsFee).div(feeDenominator);
            AmountRewardsFee += RFEE;

            feeAmount = LFEE.add(MFEE).add(RFEE);
    
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
        if(AmountRewardsFee > 0) swapAndSendDivident(AmountRewardsFee);
    }

    function addLiquidity() internal swapping {

        if(AmountLiquidityFee > 0){
            swapForLiquidity(AmountLiquidityFee);
        }

        if(AmountMarketingFee > 0){
            swapForMarketing(AmountMarketingFee);
        }

    }

    function swapBack() internal swapping {
        if(AmountRewardsFee > 0){
            swapAndSendDivident(AmountRewardsFee);
        }      
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

    function shouldAddLiquidity() internal view returns (bool) {

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        return
            _autoAddLiquidity && 
            !inSwap && 
            canSwap &&
            !automatedMarketMakerPairs[msg.sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return 
            _autoSwapBack &&
            !inSwap &&
            !automatedMarketMakerPairs[msg.sender]; 
    }


    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if(_flag) {
            _autoAddLiquidity = _flag;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function setAutoSwapBack(bool _flag) external onlyOwner {
        if(_flag) {
            _autoSwapBack = _flag;
        } else {
            _autoSwapBack = _flag;
        }
    }

    function enableClaimableExempt(bool _status) public onlyOwner {
        ClaimableOnly = _status;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
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

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isExcludedFromFees[_addr];
    }

    function enableDisableTxLimit(bool _status) public onlyOwner {
        EnableTransactionLimit = _status;
    }

    function enableDisableWalletLimit(bool _status) public onlyOwner {
        checkWalletLimit = _status;
    }

    function setWhitelistTransfer(address _adr, bool _status) public onlyOwner {
        allowTransfer[_adr] = _status;
    }

    function setInitialDistribution(bool _status) public onlyOwner{
        require(initalDistribution != _status,"Not Changed!!");
        initalDistribution = _status;
    }

    function setBuyFee(
            uint _newLp,
            uint _newMarketing,
            uint _newReward
        ) public onlyOwner {
      
        buyLiquidityFee = _newLp;
        buyMarketingFee = _newMarketing;
        buyRewardsFee = _newReward;
    }

    function setSellFee(
            uint _newLp,
            uint _newMarketing,
            uint _newReward
        ) public onlyOwner {

        sellLiquidityFee = _newLp;
        sellMarketingFee = _newMarketing;
        sellRewardsFee = _newReward;
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

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner returns (bool success){
        return IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueDividentToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner  returns (bool success) {
        return distributor.rescueToken(tokenAddress, _receiver,tokens);
    }

    function setFeeReceivers(address _marketing) public onlyOwner {
        _marketingWalletAddress = _marketing;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    function setMaxWalletLimit(uint _value) public onlyOwner {
        MaxWalletLimit = _value;
    }

    function setMaxTxLimit(uint _value) public onlyOwner {
        MaxTxLimit = _value; 
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(_balances[deadWallet]).sub(_balances[ZeroWallet]);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IPancakeSwapPair(pair).sync();
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IPancakeSwapPair(_address);
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

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _balances[pair];
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
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

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        blacklist[_botAddress] = _flag;    
    }

    function setMinSwapAmount(uint _value) external onlyOwner {
        swapTokensAtAmount = _value;
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function swapForMarketing(uint _tokens) private {
        uint initalBalance = address(this).balance;
        swapTokensForEth(_tokens);
        uint recieveBalance = address(this).balance.sub(initalBalance);
        AmountMarketingFee = AmountMarketingFee.sub(_tokens);
        payable(_marketingWalletAddress).transfer(recieveBalance);
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
            owner(),
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