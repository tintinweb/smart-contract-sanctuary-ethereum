/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/**
 * SPDX-License-Identifier: unlicensed
 * Web: voxnet.xyz
 * Community: t.me/thevoxnet
 */


pragma solidity 0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract VOXNET is IERC20, Auth {
    string constant _name = "VoxNet";
    string constant _symbol = "VOXNET";
    uint8 constant _decimals = 4;

    uint256 private _totalSupply = 1 * 10**6 * 10**_decimals;

    uint256 public devFee = 4;
    uint256 public marketingFee = 2;
    uint256 public treasuryFee = 3;
    uint256 public totalFee = devFee + marketingFee + treasuryFee;

    address private constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 private feeDistributingTransactionThreshold = 1 * 10**18;
    uint256 private feeDistributingBalanceThreshold = 1 * 10**18;

    uint256 private tokenPriceTimeWindow = 1800;

    mapping (address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    bool private tradingOpen = false;

    mapping(address => bool) public isFeeExempt;

    address private devFeeReceiver1;
    address private devFeeReceiver2;
    address private marketingFeeReceiver;
    address private treasuryFeeReceiver;

    IUniswapV2Router02 private router;

    address private WETHAddress;

    address private pairAddress;
    IUniswapV2Pair private pair;

    mapping (address => bool) private isPool;

    uint256 private tokenPrice;
    uint256 private tokenPriceTimestamp;
    uint256 private tokenPriceCumulative;

    bool private _distributingFees;
    modifier preventingDistributingFeesReentry() {
        if (!_distributingFees) {
            _distributingFees = true;
            _;
            _distributingFees = false;
        }
    }

    bool private _distributingETHFees;
    modifier preventingDistributingETHFeesReentry() {
        if (!_distributingETHFees) {
            _distributingETHFees = true;
            _;
            _distributingETHFees = false;
        }
    }

    constructor() Auth(msg.sender) {
        router = IUniswapV2Router02(routerAddress);
        WETHAddress = router.WETH();

        isFeeExempt[msg.sender] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require (_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }

        require(_balances[sender] >= amount, "Insufficient Balance");

        _balances[sender] = _balances[sender] - amount;

        uint256 amountAfterFee;

        if (!_distributingFees && (
                (isPool[sender] && !isFeeExempt[recipient]) ||
                (isPool[recipient] && !isFeeExempt[sender])
            )
        ) {
            amountAfterFee = takeFee(sender, amount);
            _balances[recipient] = _balances[recipient] + amountAfterFee;

            distributeFeesIfApplicable(amount);
        } else {
            amountAfterFee = amount;
            _balances[recipient] = _balances[recipient] + amountAfterFee;
        }

        emit Transfer(sender, recipient, amountAfterFee);
        return true;
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 treasuryFeeAmount = amount / 100 * treasuryFee;
        _balances[treasuryFeeReceiver] = _balances[treasuryFeeReceiver] + treasuryFeeAmount;

        emit Transfer(sender, treasuryFeeReceiver, treasuryFeeAmount);

        uint256 feeAmount = amount / 100 * (totalFee - treasuryFee);
        _balances[address(this)] = _balances[address(this)] + feeAmount;

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function distributeFeesIfApplicable(uint256 amount) internal {
        updateTokenPriceIfApplicable();

        if (amount * tokenPrice >= feeDistributingTransactionThreshold &&
            _balances[address(this)] * tokenPrice >= feeDistributingBalanceThreshold
        ) {
            distributeFees();
        }
    }

    function updateTokenPriceIfApplicable() internal {
        if (block.timestamp - tokenPriceTimestamp > tokenPriceTimeWindow) {
            uint256 tokenPriceCumulativeLast = getCumulativeTokenPrice();

            tokenPrice = (tokenPriceCumulativeLast - tokenPriceCumulative) / (block.timestamp - tokenPriceTimestamp);

            tokenPriceCumulative = tokenPriceCumulativeLast;
            tokenPriceTimestamp = block.timestamp;
        }
    }

    function getCumulativeTokenPrice() internal view returns (uint256) {
        if (pair.token0() == address(this)) {
            return pair.price0CumulativeLast();
        } else {
            return pair.price1CumulativeLast();
        }
    }

    function distributeFees() public preventingDistributingFeesReentry {
        uint256 tokensToSell = _balances[address(this)];

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETHAddress;

        _allowances[address(this)][routerAddress] = tokensToSell;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSell,
            0,
            path,
            address(this),
            block.timestamp
        );

        distributeETHFees();
    }

    function distributeETHFees() public preventingDistributingETHFeesReentry {
        uint256 amount = address(this).balance;

        uint256 amountDev = amount * devFee / totalFee;
        uint256 amountMarketing = amount * marketingFee / totalFee;

        (bool success, ) = payable(marketingFeeReceiver).call{
            value: amountMarketing,
            gas: 30000
        }("");

        (success, ) = payable(devFeeReceiver1).call{
            value: amountDev / 2,
            gas: 30000
        }("");

        (success, ) = payable(devFeeReceiver2).call{
            value: amountDev / 2,
            gas: 30000
        }("");
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setFees(
        uint256 _devFee,
        uint256 _marketingFee,
        uint256 _treasuryFee
    ) external authorized {
        devFee = _devFee;
        marketingFee = _marketingFee;
        treasuryFee = _treasuryFee;
        totalFee = _devFee + _marketingFee + _treasuryFee;

        require(totalFee <= 20, "Fees cannot be more than 20%");
    }

    function setFeeReceivers(
        address _devFeeReceiver1,
        address _devFeeReceiver2,
        address _marketingFeeReceiver,
        address _treasuryFeeReceiver
    ) external authorized {
        devFeeReceiver1 = _devFeeReceiver1;
        devFeeReceiver2 = _devFeeReceiver2;
        marketingFeeReceiver = _marketingFeeReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
    }

    function setFeeDistributionOptions(
        uint256 _feeDistributingTransactionThreshold,
        uint256 _feeDistributingBalanceThreshold,
        uint256 _tokenPriceTimeWindow
    ) external authorized {
        require(_tokenPriceTimeWindow > 0, "Price time window duration cannot be zero");

        feeDistributingTransactionThreshold = _feeDistributingTransactionThreshold;
        feeDistributingBalanceThreshold = _feeDistributingBalanceThreshold;
        tokenPriceTimeWindow = _tokenPriceTimeWindow;
    }

    function setPair(address _address) external onlyOwner {
        pairAddress = _address;
        pair = IUniswapV2Pair(_address);
        setIsPool(_address, true);

        tokenPrice = 0;
        tokenPriceCumulative = getCumulativeTokenPrice();
        tokenPriceTimestamp = block.timestamp;
    }

    event IsPool(address indexed addr, bool indexed isPool);

    function setIsPool(address _address, bool _isPool) public onlyOwner {
        isPool[_address] = _isPool;
        emit IsPool(_address, _isPool);
    }

    function openTrading() public onlyOwner {
        require(!tradingOpen, "Trading is already open");

        require(pairAddress != address(0), "DEX pair address must be set");

        require(
            devFeeReceiver1 != address(0) &&
            devFeeReceiver2 != address(0) &&
            marketingFeeReceiver != address(0) &&
            treasuryFeeReceiver != address(0),
            "Fee recipient addresses must be set"
        );

        tradingOpen = true;
    }
}