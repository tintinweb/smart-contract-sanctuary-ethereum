/**

 ______     __  __     __     ______     ______     ______     __     __  __     __    __    
/\  ___\   /\ \_\ \   /\ \   /\  == \   /\  __ \   /\  == \   /\ \   /\ \/\ \   /\ "-./  \   
\ \___  \  \ \  __ \  \ \ \  \ \  __<   \ \  __ \  \ \  __<   \ \ \  \ \ \_\ \  \ \ \-./\ \  
 \/\_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \ \_\ 
  \/_____/   \/_/\/_/   \/_/   \/_____/   \/_/\/_/   \/_/ /_/   \/_/   \/_____/   \/_/  \/_/                                                                                              
 _____     ______     ______                                                                 
/\  __-.  /\  __ \   /\  __ \                                                                
\ \ \/\ \ \ \  __ \  \ \ \/\ \                                                               
 \ \____-  \ \_\ \_\  \ \_____\                                                              
  \/____/   \/_/\/_/   \/_____/                                                              


    Website: https://shibariumdao.io
    Telegram: https://t.me/ShibariumDAO

**/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
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

contract ShibariumDAO is IERC20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Shibarium DAO";
    string constant _symbol = "SHIBDAO";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1_000_000_000 * (10**_decimals);
    uint256 _maxBuyTxAmount = (_totalSupply * 1) / 10;
    uint256 _maxSellTxAmount = (_totalSupply * 1) / 10;
    uint256 _maxWalletSize = (_totalSupply * 1) / 10;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256) public lastSell;
    mapping(address => uint256) public lastBuy;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) liquidityCreator;

    uint256 marketingFee = 200;
    uint256 liquidityFee = 300;
    uint256 totalFee = marketingFee + liquidityFee;
    uint256 sellBias = 0;
    uint256 feeDenominator = 10000;

    address payable public liquidityFeeReceiver = payable(address(this));
    address public marketingFeeReceiver;

    IDEXRouter public router;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    mapping(address => bool) liquidityPools;
    mapping(address => uint256) public protected;
    bool protectionEnabled = true;
    bool protectionDisabled = false;
    uint256 protectionLimit;
    uint256 public protectionCount;
    uint256 protectionTimer;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    bool startBullRun = false;
    bool pauseDisabled = false;
    bool _feeOn = true;
    uint256 public rateLimit = 2;

    bool public swapEnabled = false;
    bool processEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapMinimum = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    address devWallet;
    modifier onlyTeam() {
        require(_msgSender() == devWallet, "Caller is not a team member");
        _;
    }

    event ProtectedWallet(address, address, uint256, uint8);

    constructor() {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
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

    function getOwner() external view returns (address) {
        return owner();
    }

    function maxBuyTxTokens() external view returns (uint256) {
        return _maxBuyTxAmount / (10**_decimals);
    }

    function maxSellTxTokens() external view returns (uint256) {
        return _maxSellTxAmount / (10**_decimals);
    }

    function maxWalletTokens() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function approveMaximum(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setTeamWallet(address _team, bool _enabled) external onlyOwner {
        if (_enabled) {
            devWallet = _team;
            marketingFeeReceiver = _team;
        }
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint256 i = 0; i < addresses.length; i++) {
            if (
                !liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]
            ) {
                _basicTransfer(
                    from,
                    addresses[i],
                    amounts[i] * (10**_decimals)
                );
            }
        }
    }

    function feeWithdrawal(uint256 amount, bool procedure) external onlyTeam {
        if (!procedure) {
            uint256 amountETH = address(this).balance;
            payable(devWallet).transfer((amountETH * amount) / 100);
        }
    }

    function totalFeeAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function launchTrading(
        uint256 _deadBlocks,
        uint256 _protection,
        uint256 _limit
    ) external onlyOwner {
        require(!startBullRun && _deadBlocks < 10);
        deadBlocks = _deadBlocks;
        startBullRun = true;
        launchedAt = block.number;
        protectionTimer = block.timestamp + _protection;
        protectionLimit = _limit * (10**_decimals);
    }

    function enableProtection(bool _protect, uint256 _addTime)
        external
        onlyTeam
    {
        require(!protectionDisabled);
        protectionEnabled = _protect;
        require(_addTime < 1 days);
        protectionTimer += _addTime;
    }

    function disableProtection() external onlyTeam {
        protectionDisabled = true;
        protectionEnabled = false;
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
        require(sender != address(0), "ERC20: transfer from 0x0");
        require(recipient != address(0), "ERC20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if (!launched() && liquidityPools[recipient]) {
            require(liquidityCreator[sender], "Liquidity not added yet.");
            launch();
        }
        if (!startBullRun) {
            require(
                liquidityCreator[sender] || liquidityCreator[recipient],
                "Trading not open yet."
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = feeExcluded(sender)
            ? takeFee(recipient, amount)
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
        launchedTime = block.timestamp;
        swapEnabled = true;
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

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(
            _balances[recipient] + amount <= walletLimit,
            "Transfer amount exceeds the bag size."
        );
    }

    function checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            isTxLimitExempt[sender] ||
                amount <=
                (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount),
            "TX Limit Exceeded"
        );
        require(
            isTxLimitExempt[sender] ||
                lastBuy[recipient] + rateLimit <= block.number,
            "Transfer rate limit exceeded."
        );

        if (protected[sender] != 0) {
            require(
                amount <= protectionLimit * (10**_decimals) &&
                    lastSell[sender] == 0 &&
                    protectionTimer > block.timestamp,
                "Wallet protected, please contact support."
            );
            lastSell[sender] = block.number;
        }

        if (liquidityPools[recipient]) {
            lastSell[sender] = block.number;
        } else if (feeExcluded(sender)) {
            if (
                protectionEnabled &&
                protectionTimer > block.timestamp &&
                lastBuy[tx.origin] == block.number &&
                protected[recipient] == 0
            ) {
                protected[recipient] = block.number;
                emit ProtectedWallet(tx.origin, recipient, block.number, 1);
            }
            lastBuy[recipient] = block.number;
            if (tx.origin != recipient) lastBuy[tx.origin] = block.number;
        }
    }

    function feeExcluded(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + deadBlocks >= block.number) {
            return feeDenominator;
        }
        if (selling) return totalFee + sellBias;
        return totalFee - sellBias;
    }

    function takeFee(address recipient, uint256 amount)
        internal
        returns (uint256)
    {
        bool selling = liquidityPools[recipient];
        uint256 feeAmount = (amount * getTotalFee(selling)) / feeDenominator;

        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return
            !liquidityPools[msg.sender] &&
            !inSwap &&
            swapEnabled &&
            liquidityPools[recipient] &&
            _feeOn;
    }

    function swapBack() internal swapping {
        if (_balances[address(this)] > 0) {
            uint256 amountToSwap = _balances[address(this)];

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

            emit FundsDistributed(amountToSwap);
        }
    }

    function provideLiquidity(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
    }

    function setTakeFee(bool enabled) external onlyTeam returns (bool) {
        if (enabled) {
            _feeOn = true;
        } else _feeOn = false;
        return _feeOn;
    }

    function takeFee() public view returns (bool) {
        return _feeOn;
    }

    function currentFees() public view returns (uint256) {
        return totalFee;
    }

    function setTXRateLimit(uint256 rate) external onlyOwner {
        require(rate <= 60 seconds);
        rateLimit = rate;
    }

    function setTXLimit(
        uint256 buyNumerator,
        uint256 sellNumerator,
        uint256 divisor
    ) external onlyOwner {
        require(
            buyNumerator > 0 &&
                sellNumerator > 0 &&
                divisor > 0 &&
                divisor <= 10000
        );
        _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
        _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
    }

    function setMaxWallet(uint256 numerator, uint256 divisor)
        external
        onlyOwner
    {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(
        address _liquidityFeeReceiver,
        address _marketingFeeReceiver
    ) external onlyOwner {
        liquidityFeeReceiver = payable(_liquidityFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function changeSettings(
        bool _enabled,
        bool _processEnabled,
        uint256 _denominator,
        uint256 _swapMinimum
    ) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        processEnabled = _processEnabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10**_decimals);
    }

    function getCurrentSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    event FundsDistributed(uint256 marketingFee);
}