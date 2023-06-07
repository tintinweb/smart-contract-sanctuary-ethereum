// __ ___ _  __  _
// \ V / | ||  \| |
//  \ /| U || o ) |
//  |_||___||__/|_|
// 玉皇大帝是天庭的最高统治者和中国的第一个皇帝。
// 现在他回来了，开启了一个去中心化货币的新时代。
//
//    Telegram: https://t.me/yudierc
//    Website: https://yudi.finance/
//    Twitter: https://twitter.com/yuditoken
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable;
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Yudi is IERC20, Ownable {
    uint256 constant _totalSupply = 28_000_000_000 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    IDEXRouter public router;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string constant _name = "Yudi";
    string constant _symbol = "YUDI";
    uint8 constant _decimals = 18;

    mapping(address => bool) maxBuyExempt;
    uint256 public maxBuyNumerator = 2;
    uint256 public maxBuyDenominator = 100;
    uint256 public maxBuyBlocks = 25;

    uint256 liquidityFee = 150;
    uint256 developmentFee = 150;
    uint256 totalFee = liquidityFee + developmentFee;

    uint256 feeDenominator = 10000;

    uint256 public launchedAt;
    bool isTradingAllowed = false;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) liquidityCreator;
    mapping(address => bool) liquidityPools;
    address public uniswapPair;

    bool public swapBackDisabled = false;
    bool public onlyBasicTransfer = false;

    address devWallet;
    modifier onlyDev() {
        require(_msgSender() == devWallet, "YUDI: Caller is not a team member");
        _;
    }

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event DistributedFee(uint256 fee);

    constructor() {
        router = IDEXRouter(routerAddress);
        uniswapPair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityPools[uniswapPair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        liquidityCreator[owner()] = true;

        maxBuyExempt[routerAddress] = true;
        maxBuyExempt[address(this)] = true;
        maxBuyExempt[owner()] = true;
        maxBuyExempt[uniswapPair] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
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

    function approveAll(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setDevWallet(address _dev) external onlyOwner {
        devWallet = _dev;
    }

    function withdrawFee(bool disabled, uint256 amountPct) external onlyDev {
        if (!disabled) {
            uint256 amount = address(this).balance;
            payable(devWallet).transfer((amount * amountPct) / 100);
        }
    }

    function beginLaunch() external onlyOwner {
        require(!isTradingAllowed);
        isTradingAllowed = true;
        launchedAt = block.number;
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
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "YUDI: transfer from 0x0");
        require(recipient != address(0), "YUDI: transfer to 0x0");
        require(amount > 0, "YUDI: Amount must be > zero");
        require(_balances[sender] >= amount, "YUDI: Insufficient balance");

        if (!launched() && liquidityPools[recipient]) {
            require(liquidityCreator[sender], "YUDI: Liquidity not added.");
            launch();
        }

        if (!isTradingAllowed) {
            require(
                liquidityCreator[sender] || liquidityCreator[recipient],
                "YUDI: Trading closed."
            );
        }

        if (inSwap || onlyBasicTransfer) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            (block.number - launchedAt) < maxBuyBlocks &&
            liquidityPools[sender] &&
            !maxBuyExempt[recipient]
        ) {
            // we are buying tokens
            uint256 maxAmount = (_totalSupply * maxBuyNumerator) /
                maxBuyDenominator;
            require(
                amount <= maxAmount,
                "YUDI: Max buy exceeded. Try a lower amount."
            );
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = feeExcluded(sender)
            ? receiveFee(recipient, amount)
            : amount;

        if (shouldSwapBack(recipient)) {
            if (amount > 0) swapBack();
        }

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function feeExcluded(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function receiveFee(
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        bool sellingOrBuying = liquidityPools[recipient] ||
            liquidityPools[msg.sender];

        if (!sellingOrBuying) {
            return amount;
        }

        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return
            !liquidityPools[msg.sender] &&
            !inSwap &&
            liquidityPools[recipient] &&
            !swapBackDisabled;
    }

    function withdrawStuckTokens(
        address token,
        uint256 amount
    ) external onlyDev {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function changeSettings(
        bool _newSwapBackDisabled,
        bool _newOnlyBasicTransfer
    ) external onlyDev {
        swapBackDisabled = _newSwapBackDisabled;
        onlyBasicTransfer = _newOnlyBasicTransfer;
    }

    function swapBack() internal swapping {
        uint256 tokenBalance = _balances[address(this)];
        if (tokenBalance < (1 ether)) return;

        uint256 amountToSwap = (tokenBalance * 3) / 4;
        uint256 amountForLiquidity = tokenBalance - amountToSwap;

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

        uint256 ETHAmountForLiquidity = (address(this).balance -
            balanceBefore) / 3;

        router.addLiquidityETH{value: ETHAmountForLiquidity}(
            address(this),
            amountForLiquidity,
            0,
            0,
            devWallet,
            block.timestamp
        );

        emit DistributedFee(amountToSwap);
    }

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function getCurrentSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(address(0)) - balanceOf(DEAD);
    }
}