/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-08
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

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

    function mint(address tokenOwner, uint256 tokens)
        external
        returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PolyToken is ERC20, Ownable {
    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetFees(uint256 DevFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event StuckBalanceSent(uint256 amountETH, address recipient);

    // Mappings
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    // Basic Contract Info
    string constant _name = "PolyToken";
    string constant _symbol = "POLY";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 100_000_000 ether;
    mapping(address => bool) isGame;

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 10) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 10) / 1000;
    bool public enableMaxWallet = true;

    // Fee receiver
    uint256 public TreasuryFeeBuy = 50;
    uint256 public LiquidityFeeBuy = 30;
    uint256 public BurnFeeBuy = 20;

    uint256 public TreasuryFeeSell = 50;
    uint256 public LiquidityFeeSell = 30;
    uint256 public BurnFeeSell = 20;

    uint256 public TotalBase =
        TreasuryFeeBuy +
            TreasuryFeeSell +
            BurnFeeBuy +
            BurnFeeSell +
            LiquidityFeeBuy +
            LiquidityFeeSell;

    // Fee receiver & Dead Wallet
    address public TreasuryWallet = 0x594F3Ce976E89CC56C5725D59BF0d93A91FD8B91;
    address private constant DEAD = 0x0000000000000000000000000000000000000000;

    // Router
    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 10000) * 3; // 0.3%

    bool public isTradingEnabled = true;
    address public tradingEnablerRole;
    uint256 public tradingTimestamp;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address game) Ownable(msg.sender) {
        router = IDEXRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[owner][game] = type(uint256).max;

        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;

        isFeeExempt[pair] = true;
        isTxLimitExempt[pair] = true;

        isFeeExempt[game] = true;
        isTxLimitExempt[game] = true;
        isGame[game] = true;

        isFeeExempt[TreasuryWallet] = true;
        isTxLimitExempt[TreasuryWallet] = true;

        tradingEnablerRole = owner;
        tradingTimestamp = block.timestamp;

        _balances[owner] = (_totalSupply * 100) / 100;

        emit Transfer(address(0), owner, (_totalSupply * 100) / 100);
    }

    receive() external payable {}

    // Basic Internal Functions
    function setTreasuryWallet(address treasury) external onlyOwner {
        TreasuryWallet = treasury;
        isFeeExempt[TreasuryWallet] = true;
        isTxLimitExempt[TreasuryWallet] = true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    modifier onlyGame() {
        require(isGame[msg.sender], "Caller isn't game.");
        _;
    }

    function setGame(address game) external onlyOwner {
        isGame[game] = true;
        isFeeExempt[game] = true;
        isTxLimitExempt[game] = true;
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    ////////////////////////////////////////////////
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                (amount);
        }

        return _transferFrom(sender, recipient, amount);
    }

    function mint(address tokenOwner, uint256 tokens)
        external
        override
        onlyGame
        returns (bool success)
    {
        _balances[tokenOwner] = _balances[tokenOwner] + (tokens);
        _totalSupply = _totalSupply + (tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }

    function renounceTradingEnablerRole() public onlyOwner {
        tradingEnablerRole = address(0x0);
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public onlyOwner {
        isTradingEnabled = _isTradingEnabled;
        tradingTimestamp = block.timestamp;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        // burn
        if (recipient == DEAD) {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
            _totalSupply = _totalSupply - amount;
            emit Transfer(sender, recipient, amount);
            return true;
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        require(
            isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled,
            "Not authorized to trade yet"
        );

        // Checks max transaction limit
        if (
            sender != owner &&
            recipient != owner &&
            recipient != DEAD &&
            recipient != pair &&
            enableMaxWallet
        ) {
            require(
                isTxLimitExempt[recipient] ||
                    (amount <= _maxTxSize &&
                        _balances[recipient] + amount <= _maxWalletSize),
                "Transfer amount exceeds the MaxWallet size."
            );
        }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? amount
            : takeFee(sender, recipient, amount);

        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
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

    // Internal Functions

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 treasuryFeeAmount = 0;
        uint256 liquidityFeeAmount = 0;
        uint256 burnFeeAmount = 0;

        if (sender == pair && recipient != pair) {
            feeAmount =
                (amount * (TreasuryFeeBuy + BurnFeeBuy + LiquidityFeeBuy)) /
                1000;
            treasuryFeeAmount = (amount * TreasuryFeeBuy) / 1000;
            liquidityFeeAmount = (amount * LiquidityFeeBuy) / 1000;
            burnFeeAmount = (amount * BurnFeeBuy) / 1000;
        }
        if (sender != pair && recipient == pair) {
            feeAmount =
                (amount * (TreasuryFeeSell + BurnFeeSell + LiquidityFeeSell)) /
                1000;
            treasuryFeeAmount = (amount * TreasuryFeeSell) / 1000;
            liquidityFeeAmount = (amount * LiquidityFeeSell) / 1000;
            burnFeeAmount = (amount * BurnFeeSell) / 1000;
        }

        if (treasuryFeeAmount > 0) {
            _balances[TreasuryWallet] =
                _balances[TreasuryWallet] +
                treasuryFeeAmount;
            emit Transfer(sender, TreasuryWallet, treasuryFeeAmount);
        }

        if (burnFeeAmount > 0) {
            _balances[DEAD] = _balances[DEAD] + burnFeeAmount;
            _totalSupply = _totalSupply - burnFeeAmount;
            emit Transfer(sender, DEAD, burnFeeAmount);
        }

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled;
    }

    function swapAndLiquify(uint256 amount) internal swapping {
        uint256 toSwap = amount / 2;
        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;

        if (deltaBalance > 0) {
            addLiquidity(toSwap, deltaBalance);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        approve(address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    // External Functions

    function setMaxWalletAndTx(uint256 _maxWalletSize_, uint256 _maxTxSize_)
        external
        onlyOwner
    {
        require(
            _maxWalletSize_ >= _totalSupply / 1000 &&
                _maxTxSize_ >= _totalSupply / 1000,
            "Can't set MaxWallet or Tx below 0.1%"
        );
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setEnableMaxWallet(bool enable) external onlyOwner {
        enableMaxWallet = enable;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setFees(
        uint256 _TreasuryFeeBuy,
        uint256 _MarketingFeeBuy,
        uint256 _LiquidityFeeBuy,
        uint256 _TreasuryFeeSell,
        uint256 _MarketingFeeSell,
        uint256 _LiquidityFeeSell
    ) external onlyOwner {

        TreasuryFeeBuy = _TreasuryFeeBuy;
        BurnFeeBuy = _MarketingFeeBuy;
        LiquidityFeeBuy = _LiquidityFeeBuy;

        TreasuryFeeSell = _TreasuryFeeSell;
        BurnFeeSell = _MarketingFeeSell;
        LiquidityFeeSell = _LiquidityFeeSell;

        TotalBase =
            TreasuryFeeBuy +
            TreasuryFeeSell +
            BurnFeeBuy +
            BurnFeeSell +
            LiquidityFeeBuy +
            LiquidityFeeSell;

        emit SetFees(TreasuryFeeBuy);
    }
}