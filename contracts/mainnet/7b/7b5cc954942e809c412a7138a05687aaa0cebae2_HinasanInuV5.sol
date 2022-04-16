/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// File: interfaces/IUniswapV2Factory.sol



pragma solidity ^0.7.4;

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
// File: interfaces/IUniswapV2Router01.sol



pragma solidity ^0.7.4;

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
// File: interfaces/IUniswapV2Router02.sol



pragma solidity ^0.7.4;


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
// File: interfaces/IUniswapV2Pair.sol



pragma solidity ^0.7.4;

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
// File: libraries/SafeMathInt.sol




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
// File: libraries/SafeMath.sol



pragma solidity ^0.7.4;

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
// File: contracts/Ownable.sol



pragma solidity ^0.7.4;

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
        require(isOwner(), "Only owner can call this function");
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
// File: contracts/IERC20.sol



pragma solidity ^0.7.4;

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
// File: contracts/ERC20Detailed.sol



pragma solidity ^0.7.4;


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
// File: contracts/HinasanInuV5.sol



pragma solidity ^0.7.4;









contract HinasanInuV5 is ERC20Detailed, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint8 public _decimals = 5;

    IUniswapV2Pair public pairContract;
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant DECIMALS = 18;

    //buy fees
    uint256 public buyTreasuryFee = 40;
    uint256 public buyLiquidityFee = 30;
    uint256 public buyBurnerTokenFee = 20;
    uint256 public totalBuyFee = buyTreasuryFee.add(buyBurnerTokenFee).add(buyLiquidityFee); // 9%

    //sell fees
    uint256 public sellTreasuryFee = 40;
    uint256 public sellLiquidityFee = 30;
    uint256 public sellBurnerTokenFee = 20;
    uint256 public totalSellFee = sellTreasuryFee.add(sellLiquidityFee).add(sellBurnerTokenFee); // 9%
    uint256 public feeDenominator = 1000;

    //counters
    uint256 internal buyTreasuryFeeAmount = 0;
    uint256 internal buyBurnerTokenFeeAmount = 0;
    uint256 internal buyLiquidityFeeAmount = 0;
    uint256 internal sellTreasuryFeeAmount = 0;
    uint256 internal sellLiquidityFeeAmount = 0;
    uint256 internal sellBurnerTokenFeeAmount = 0;

    //burnerToken
    address[] tokens;
    address activeToken = DEAD;
    IERC20 activeTokenContract;
    mapping (address => uint256) tokensBoughtAndBurned;
    mapping (address => uint256) ethSpentOnToken;
    uint256 totalEthSpent = 0;

    uint256 public startTime;
    uint256 public sellLimit = 25;
    uint256 public holdLimit = 25;
    uint256 public limitDenominator = 10000;
    uint256 public constant TIME_STEP = 1 days;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public treasuryReceiver;
    address public pairAddress;
    bool public swapBackEnabled = true;
    IUniswapV2Router02 public router;
    address public pair;
    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 public _totalSupply = 1 * 10**9 * 10**DECIMALS;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public blacklist;
    mapping(address => mapping(uint256 => uint256)) public sold;
    mapping(address => bool) public _excludeFromLimit;
    mapping(address => bool) public authorized;

    bool public transferEnabled = false;
    bool public autoAddLiquidity = true;
    bool public autoBuyAndBurnToken = true;

    modifier checkLimit(address from, address to, uint256 value) {
        if(!_excludeFromLimit[from]) {
            require(sold[from][getCurrentDay()] + value <= getUserSellLimit(), "Cannot sell or transfer more than limit.");
        }
        _;
        if(!_excludeFromLimit[to]) {
            require(_balances[to] <= getUserHoldLimit(), "Cannot buy more than limit.");
        }
    }

    constructor(address _treasury, address _router) 
        ERC20Detailed("Hinasan Inu", "HINU", uint8(DECIMALS)) Ownable() 
    {
        router = IUniswapV2Router02(_router); 
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
      
        treasuryReceiver = _treasury;
        
        _allowances[address(this)][address(router)] = uint256(-1);
        pairAddress = pair;
        pairContract = IUniswapV2Pair(pair);

        _excludeFromLimit[address(this)] = true;
        _excludeFromLimit[pair] = true;
        _excludeFromLimit[treasuryReceiver] = true;

        _balances[treasuryReceiver] = _totalSupply;
        _allowances[treasuryReceiver][address(router)] = _totalSupply;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[address(this)] = true;
        authorized[address(this)] = true;
        authorized[treasuryReceiver] = true;

        //First token active is KIBA ETH
        activeToken = 0x005D1123878Fc55fbd56b54C73963b234a64af3c;
        tokens.push(activeToken);
        activeTokenContract = IERC20(activeToken);

        _transferOwnership(_treasury);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
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
    ) 
        internal 
        checkLimit(sender, recipient, amount) 
        returns (bool)
    {

        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");
        require(transferEnabled || authorized[sender] || authorized[recipient], "Transfer not yet enabled");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(address sender, uint256 amount) internal  returns (uint256) {
        uint256 feeAmount = 0;
        if(sender==pair){   //buy
            feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(amount.mul(totalBuyFee).div(feeDenominator));

            buyBurnerTokenFeeAmount = buyBurnerTokenFeeAmount.add(feeAmount.mul(buyBurnerTokenFee).div(totalBuyFee));
            buyTreasuryFeeAmount = buyTreasuryFeeAmount.add(feeAmount.mul(buyTreasuryFee).div(totalBuyFee));
            buyLiquidityFeeAmount = buyLiquidityFeeAmount.add(feeAmount.mul(buyLiquidityFee).div(totalBuyFee));
        } 
        else {  //sell
            feeAmount = amount.mul(totalSellFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(amount.mul(totalSellFee).div(feeDenominator));

            sellBurnerTokenFeeAmount = sellBurnerTokenFeeAmount.add(feeAmount.mul(sellBurnerTokenFee).div(totalSellFee));
            sellTreasuryFeeAmount = sellTreasuryFeeAmount.add(feeAmount.mul(sellTreasuryFee).div(totalSellFee));
            sellLiquidityFeeAmount = sellLiquidityFeeAmount.add(feeAmount.mul(sellLiquidityFee).div(totalSellFee));
        }
        
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function swapBack() internal swapping {
        uint256 amount = _balances[address(this)];

        uint256 totalCollectedAmount = 
            buyBurnerTokenFeeAmount
            .add(buyTreasuryFeeAmount)
            .add(buyLiquidityFeeAmount)
            .add(sellBurnerTokenFeeAmount)
            .add(sellTreasuryFeeAmount)
            .add(sellLiquidityFeeAmount);

        uint256 totalCollectedAmountToSwap = totalCollectedAmount.sub(sellLiquidityFeeAmount.add(buyLiquidityFeeAmount));

        if( totalCollectedAmount == 0) {
            return;
        }

        uint256 amountToLiq = amount.mul(sellLiquidityFeeAmount.add(buyLiquidityFeeAmount)).div(totalCollectedAmount);

        //add liquidity
        if(autoAddLiquidity){
            addLiquidity(amountToLiq);
        }

        //Swap back
        uint256 amountToSwap = _balances[address(this)];
        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(
            balanceBefore
        );

        //send taxed fee to treasury
        (bool success, ) = payable(treasuryReceiver).call{
            value: amountETH.mul(buyTreasuryFeeAmount.add(sellTreasuryFeeAmount)).div(totalCollectedAmountToSwap),
            gas: 30000
        }("");

        //buy and burn tokens
        if(autoBuyAndBurnToken) {
            _buyAndBurnTokens(amountETH.mul(buyBurnerTokenFeeAmount.add(sellBurnerTokenFeeAmount)).div(totalCollectedAmountToSwap));
        }

        //reset counters
        buyBurnerTokenFeeAmount = 0;
        buyTreasuryFeeAmount = 0;
        buyLiquidityFeeAmount = 0;
        sellBurnerTokenFeeAmount = 0;
        sellTreasuryFeeAmount = 0;
        sellLiquidityFeeAmount = 0;
    }

    function addLiquidity(uint256 _amount) internal {

        uint256 amountToLiquify = _amount.div(2);
        uint256 amountToSwap = _amount.sub(amountToLiquify);

        if( amountToSwap == 0 ) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0&&amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
        }
    }

    function _buyAndBurnTokens(uint256 amountEth) internal {

        //set path variable
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = activeToken;

        //buy tokens
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountEth}(
            0,
            path,
            address(this),
            block.timestamp
        );

        //update info
        uint256 activeTokenBalance = activeTokenContract.balanceOf(address(this));
        tokensBoughtAndBurned[activeToken] = tokensBoughtAndBurned[activeToken].add(activeTokenBalance);
        ethSpentOnToken[activeToken] = ethSpentOnToken[activeToken].add(amountEth);
        totalEthSpent = totalEthSpent.add(amountEth);

        //burn tokens
        activeTokenContract.approve(address(router), activeTokenBalance);
        activeTokenContract.transfer(DEAD, activeTokenBalance);
    }

    function buyAndBurnTokens(uint256 amountEth) external onlyOwner() {
        require(address(this).balance >= amountEth, "Not enough balance");
        require(inSwap==false, "Currently in swap");
        _buyAndBurnTokens(amountEth);
    }

    function setToken(address _token) external onlyOwner() {
        activeToken = _token;

        if(!findToken(_token)){
            tokens.push(_token);
        }

        activeTokenContract = IERC20(_token);
    }

    function findToken(address _token) internal view returns(bool){
        for(uint256 i=0; i<tokens.length; i++){
            if(tokens[i]==_token){
                return true;
            }
        }
        return false;
    }

    function getActiveToken() external view returns (address){
        return activeToken;
    }

    //Testing purposes
    function readBalance() external view returns(uint256) {
        return address(this).balance;
    }

    //Testing purposes
    function readTokenBalance(address _token) external view returns (uint256){
        IERC20 _tokenContract = IERC20(_token);
        return _tokenContract.balanceOf(address(this));
    }

    //Testing purposes
    function readTokenBalanceDeadAddress(address _token) external view returns (uint256){
        IERC20 _tokenContract = IERC20(_token);
        return _tokenContract.balanceOf(DEAD);
    }

    function getTokensBoughtAddresses() external view returns(address[] memory){
        return tokens;
    }

    function getTokenAmountBought(address _token) external view returns(uint256){
        return tokensBoughtAndBurned[_token];
    }

    function getEthAmountSpentOnToken(address _token) external view returns(uint256){
        return ethSpentOnToken[_token];
    }

    function getTotalEthSpent() external view returns (uint256){
        return totalEthSpent;
    }

    function getTokensAmountBought() external view returns(uint256[] memory){
        uint256[] memory _amounts = new uint256[](tokens.length);

        for(uint256 i=0;i<tokens.length;i++){
            _amounts[i] = tokensBoughtAndBurned[tokens[i]];
        }

        return _amounts;
    }

    function getEthAmountsSpentOnToken() external view returns(uint256[] memory){
        uint256[] memory _amounts = new uint256[](tokens.length);

        for(uint256 i=0;i<tokens.length;i++){
            _amounts[i] = ethSpentOnToken[tokens[i]];
        }

        return _amounts;
    }

    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }

    function getCurrentDay() internal view returns (uint256) {
        return minZero(block.timestamp, startTime).div(TIME_STEP);
    }

    function getUserHoldLimit() internal view returns (uint256) {
        return getCirculatingSupply().mul(holdLimit).div(limitDenominator);
    }

    function getUserSellLimit() internal view returns (uint256) {
        return getCirculatingSupply().mul(sellLimit).div(limitDenominator);
    }

    function shouldTakeFee(address from, address to) internal view returns (bool){
        return (pair == from || pair == to) && !_isFeeExempt[from];
    }

    function shouldSwapBack() internal view returns (bool) {
        return 
            !inSwap &&
            msg.sender != pair &&
            transferEnabled &&
            swapBackEnabled; 
    }

    //Can only be activated, not deactivated
    function setTransferEnabled() external onlyOwner{
        authorized[pair] = true;
        transferEnabled = true;
    }

    function setSwapBackEnabled(bool flag) external onlyOwner{
        swapBackEnabled = flag;
    }

    function setAuthorized(address[] memory _addr, bool _flag) external onlyOwner() {
        for(uint256 i=0; i<_addr.length; i++){
            authorized[_addr[i]] = _flag;
        }
    }

    function setAutoAddMechanisms(bool _autoAddLiq, bool _autoBuyAndBurnToken) external onlyOwner(){
        autoAddLiquidity = _autoAddLiq;
        autoBuyAndBurnToken = _autoBuyAndBurnToken;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256) {
        return _allowances[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
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

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (_totalSupply.sub(_balances[DEAD]).sub(_balances[ZERO]));
    }

    function getPair() external view returns (address) {
        return pair;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external onlyOwner {
        IUniswapV2Pair(pair).sync();
    }

    function setLimit(uint256 _holdLimit, uint256 _sellLimit) public onlyOwner {
        require(_holdLimit >= 1 && _holdLimit <= 1000, "Invalid hold limit");
        require(_sellLimit >= 1 && _sellLimit <= 1000, "Invalid sell limit");
        holdLimit = _holdLimit;
        sellLimit = _sellLimit;
    }

    function setFees (uint256 buytreasf,uint256 buyburnertokenf, uint256 selltreasf, uint256 sellburnertokenf, uint256 sellliqf) external onlyOwner{
        buyTreasuryFee = buytreasf;
        buyBurnerTokenFee = buyburnertokenf;
        totalBuyFee = buyTreasuryFee.add(buyBurnerTokenFee);
        sellTreasuryFee = selltreasf;
        sellBurnerTokenFee = sellburnertokenf;
        sellLiquidityFee = sellliqf;
        totalSellFee = sellTreasuryFee.add(sellBurnerTokenFee).add(sellLiquidityFee);
        require(totalBuyFee.add(totalSellFee) <= 300, "Total buy+sell fee can't ever be above 30%");
    }

    function setWhitelist(address[] memory addr, bool flag) external onlyOwner {
        for(uint256 i=0; i<addr.length; i++){
            authorized[addr[i]] = flag;
            _isFeeExempt[addr[i]] = flag;
            _excludeFromLimit[addr[i]] = flag;
        }
    }

    function setExcludeFromLimit(address _address, bool _bool) public onlyOwner {
        _excludeFromLimit[_address] = _bool;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "Only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;    
    }

    function setPairAddress(address _pairAddress) public onlyOwner {
        pairAddress = _pairAddress;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address who) external view override returns (uint256) {
        return _balances[who];
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    receive() external payable {}
}