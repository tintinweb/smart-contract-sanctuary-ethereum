/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
}

interface IUniswapV2Pair {
    function sync() external;
}


contract Shiburai is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    uint256 internal constant ONE = 10**18;
    address internal constant ZERO_ADDRESS =
        0x0000000000000000000000000000000000000000; 
    
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;


    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public automatedMarketMakerRouters;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) private _lastTX;
    mapping(address => uint256) private _lastTransfer;
    mapping(address => uint256) private _lastDailyTransferedAmount;

    uint256 public nativeRewardsFeeForSelling = 5;
    uint256 public projectFeeForSelling = 5;
    uint256 public liquidityFeeForSelling = 2;
    uint256 public nativeRewardsFeeForBuying = 5;
    uint256 public projectFeeForBuying = 5;
    uint256 public liquidityFeeForBuying = 2;
    uint256 public nativeRewardsFeeForTransfering = 5;
    uint256 public projectFeeForTransfering = 5;
    uint256 public liquidityFeeForTransfering = 2;
    uint256 private maxTXAmount = 75000 * (ONE);
    uint256 public swapTokensAtAmount = 20000 * (ONE);
    uint256 public totalFeesForSelling =
        nativeRewardsFeeForSelling.add(projectFeeForSelling).add(
            liquidityFeeForSelling
        );
    uint256 public totalFeesForBuying =
        nativeRewardsFeeForBuying.add(projectFeeForBuying).add(
            liquidityFeeForBuying
        );
    uint256 public totalFeesForTransfering =
        nativeRewardsFeeForTransfering.add(projectFeeForTransfering).add(
            liquidityFeeForTransfering
        );
    uint256 public firstLiveBlock;
    uint256 public firstLiveBlockNumber;
    uint256 public maxHoldings = 150000* (ONE);
    uint256 public maximumDailyAmountToSell = 5 * maxTXAmount;

    bool public swapEnabled = true;
    bool public paused = true;
    bool public maxTXEnabled = true;
    bool public maxHoldingsEnabled = true;
    bool public antiSnipeBot = true;
    bool public cooldown = true;
    bool public takeFees = true;
    bool public dailyCoolDown;
    bool public enableMaxDailySell;
    bool private swapping;

    address payable _projectWallet;
    address public _nukeRecipient = DEAD;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event MaxDailyAmountToSellChanged(uint256 oldAmount, uint256 newAmount);
    event MaxHoldingsChanged(
        uint256 oldHoldings,
        uint256 newHoldings,
        bool maxHoldingsEnabled
    );
    event FeesChanged(
        uint256 totalFeesForBuying,
        uint256 totalFeesForSelling,
        uint256 totalFeesForTransfering
    );
    event MaxTXAmountChanged(uint256 oldMaxTXAmount, uint256 maxTXAmount);
    event SwapTokensAtAmountChanged(
        uint256 oldSwapTokensAtAmount,
        uint256 swapTokensAtAmount
    );



    constructor() ERC20("SHIBURAI", "SHB") {
        _updateUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_projectWallet, true);
        excludeFromFees(address(this), true);

        _mint(owner(), 27020401250 * (ONE));
    }

    receive() external payable {}

    function setWeth(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setNukeRecipient(address _newNukeRecipient) external onlyOwner{
        _nukeRecipient = _newNukeRecipient;
    }
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function toggleCooldown() external onlyOwner {
        cooldown = !cooldown;
    }


    function _updateUniswapV2Router(address newAddress)
        internal
        returns (address)
    {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        automatedMarketMakerRouters[address(uniswapV2Router)] = false;
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), WETH);
        if (_uniswapV2Pair == ZERO_ADDRESS) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), WETH);
        }
        automatedMarketMakerRouters[newAddress] = true;
        uniswapV2Pair = _uniswapV2Pair;
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        return uniswapV2Pair;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        _updateUniswapV2Router(newAddress);
    }


    function airdrop(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "Array sizes must be equal"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i].mul(ONE);
            _transfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account already 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setTakeFees(bool _takeFees) external onlyOwner {
        require(takeFees != _takeFees, "Updating to current value, takeFees");
        takeFees = _takeFees;
    }

    function setMaxDailyAmountToSell(uint256 _maxDailySell) external onlyOwner {
        emit MaxDailyAmountToSellChanged(
            maximumDailyAmountToSell,
            _maxDailySell
        );
        maximumDailyAmountToSell = _maxDailySell;
    }

    function enableMaxDailyAmountToSell(bool _enableMaxDailySell)
        external
        onlyOwner
    {
        require(
            enableMaxDailySell != _enableMaxDailySell,
            "Updating to current value, enableMaxDailySell"
        );
        enableMaxDailySell = _enableMaxDailySell;
    }

    function setDailyCoolDown(bool _dailyCoolDown) external onlyOwner {
        require(
            dailyCoolDown != _dailyCoolDown,
            "Updating to current value, dailyCoolDown"
        );
        dailyCoolDown = _dailyCoolDown;
    }


    function setAutomatedMarketMakerRouter(address router, bool value)
        external
        onlyOwner
    {
        require(
            router != address(uniswapV2Router),
            "Router cannot be removed from automatedMarketMakerRouters"
        );
        require(
            automatedMarketMakerRouters[router] != value,
            "Automated market maker router is already set to that value"
        );
        automatedMarketMakerRouters[router] = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;
    }


    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }




    function setProjectWallet(address projectWallet) external onlyOwner {
        _projectWallet = payable(projectWallet);
        _isExcludedFromFees[projectWallet] = true;
        emit ExcludeFromFees(projectWallet, true);
    }

    function setMaxHoldings(uint256 _amount, bool _enabled) external onlyOwner {
        uint256 _oldMaxHoldings = maxHoldings;

        maxHoldings = _amount.mul(ONE);
        maxHoldingsEnabled = _enabled;

        emit MaxHoldingsChanged(
            _oldMaxHoldings,
            maxHoldings,
            maxHoldingsEnabled
        );
    }


    function setFees(
        uint256 _nativeRewardFeeForBuying,
        uint256 _liquidityFeeForBuying,
        uint256 _projectFeeForBuying,
        uint256 _nativeRewardFeeForSelling,
        uint256 _liquidityFeeForSelling,
        uint256 _projectFeeForSelling,
        uint256 _nativeRewardFeeForTransfering,
        uint256 _liquidityFeeForTransfering,
        uint256 _projectFeeForTransfering
    ) external onlyOwner {
        nativeRewardsFeeForBuying = _nativeRewardFeeForBuying;
        liquidityFeeForBuying = _liquidityFeeForBuying;
        projectFeeForBuying = _projectFeeForBuying;
        totalFeesForBuying = nativeRewardsFeeForBuying
            .add(liquidityFeeForBuying)
            .add(projectFeeForBuying);
        nativeRewardsFeeForSelling = _nativeRewardFeeForSelling;
        liquidityFeeForSelling = _liquidityFeeForSelling;
        projectFeeForSelling = _projectFeeForSelling;
        totalFeesForSelling = nativeRewardsFeeForSelling
            .add(liquidityFeeForSelling)
            .add(projectFeeForSelling);

        nativeRewardsFeeForTransfering = _nativeRewardFeeForTransfering;
        liquidityFeeForTransfering = _liquidityFeeForTransfering;
        projectFeeForTransfering = _projectFeeForTransfering;
        totalFeesForTransfering = nativeRewardsFeeForTransfering
            .add(liquidityFeeForTransfering)
            .add(projectFeeForTransfering);

        emit FeesChanged(
            totalFeesForBuying,
            totalFeesForSelling,
            totalFeesForTransfering
        );
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }


    function toggleAntiSnipeBot() external onlyOwner {
        antiSnipeBot = !antiSnipeBot;
    }

    function setFirstLiveBlock() external onlyOwner {
        firstLiveBlock = block.timestamp;
        firstLiveBlockNumber = block.number;
        paused = false;
    }


    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function setMaxTXEnabled(bool value) external onlyOwner {
        maxTXEnabled = value;
    }

    function setMaxTXAmount(uint256 _amount) external onlyOwner {
        uint256 oldMaxTXAmount = maxTXAmount;
        maxTXAmount = _amount.mul(ONE);
        emit MaxTXAmountChanged(oldMaxTXAmount, maxTXAmount);
    }

    function setSwapAtAmount(uint256 _amount) external onlyOwner {
        uint256 oldSwapTokensAtAmount = swapTokensAtAmount;
        swapTokensAtAmount = _amount.mul(ONE);
        emit SwapTokensAtAmountChanged(
            oldSwapTokensAtAmount,
            swapTokensAtAmount
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !isBlacklisted[from] &&
                !isBlacklisted[to] &&
                !isBlacklisted[tx.origin],
            "Blacklisted address"
        );
        if (from != owner()) {
            require(!paused, "trading paused");
        }

        if (from != owner() && to != owner()) {
            checkTransactionParameters(from, to, amount);
        }

        if (isBlacklisted[tx.origin]) {
            return;
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            swapTokensAtAmount;
        if (
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !automatedMarketMakerRouters[from] &&
            overMinimumTokenBalance
        ) {
            swapping = true;
            _swapAndDistribute(contractTokenBalance);
            swapping = false;
        }

        bool takeFee = !swapping;
        if (
            _isExcludedFromFees[from] ||
            _isExcludedFromFees[to] ||
            !takeFees ||
            from == owner() ||
            to == owner()
        ) {
            takeFee = false;
        }
        uint256 fees;
        if (takeFee) {
            if (automatedMarketMakerPairs[to]) {
                fees = amount.mul(totalFeesForSelling).div(100);
            } else if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(totalFeesForBuying).div(100);
            } else {
                fees = amount.mul(totalFeesForTransfering).div(100);
            }
            //amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount.sub(fees));
    }

    function swapAndDistribute() external {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            swapTokensAtAmount;
        
        require(overMinimumTokenBalance, "We need more Shiburai");
        swapping = true;
        _swapAndDistribute(contractTokenBalance);
        swapping = false;
    }

    function _swapAndDistribute(uint256 tokens) private {
        uint256 liquidityFee = liquidityFeeForSelling +
            liquidityFeeForBuying +
            liquidityFeeForTransfering;
        uint256 projectFee = projectFeeForSelling +
            projectFeeForBuying +
            projectFeeForTransfering;
        uint256 totalFees = totalFeesForSelling +
            totalFeesForBuying +
            totalFeesForTransfering;

        uint256 _liqTokens = tokens.mul(liquidityFee).div(totalFees);
        uint256 tokensToSave = _liqTokens.div(2);
        uint256 tokensToSwap = tokens.sub(tokensToSave);
        uint256 preBalance = address(this).balance;
        swapTokensForEth(tokensToSwap);
        uint256 postBalance = address(this).balance.sub(preBalance);
        uint256 ethForProject = (postBalance.mul(projectFee).div(totalFees));
        _projectWallet.transfer(ethForProject);
        addLiquidity(tokensToSave, address(this).balance);
    }

    function checkTransactionParameters(
        address from,
        address to,
        uint256 amount
    ) private {
        if (dailyCoolDown && automatedMarketMakerPairs[to]) {
            require(
                _lastTransfer[from] + 600 <= block.timestamp,
                "One sell per day is allowed"
            );
        }

        if (automatedMarketMakerPairs[to]) {
            if (_lastTransfer[from] + 600 >= block.timestamp) {
                _lastDailyTransferedAmount[from] += amount;
            } else {
                _lastDailyTransferedAmount[from] = amount;
            }

            _lastTransfer[from] = block.timestamp;
        }

        if (enableMaxDailySell) {
            require(
                _lastDailyTransferedAmount[from] <= maximumDailyAmountToSell,
                "Max daily sell amount was reached"
            );
        }

        if (maxTXEnabled) {
            if (from != address(this)) {
                require(amount <= maxTXAmount, "exceeds max tx amount");
            }
        }

        if (cooldown) {
            if (from != address(this) && to != address(this)) {
                if (
                    !automatedMarketMakerPairs[to] &&
                    !automatedMarketMakerRouters[from]
                ) {
                    require(
                        block.timestamp >= (_lastTX[to] + 30 seconds),
                        "Cooldown in effect"
                    );
                    _lastTX[to] = block.timestamp;
                }
                if (
                    !automatedMarketMakerPairs[from] &&
                    !automatedMarketMakerRouters[from]
                ) {
                    require(
                        block.timestamp >= (_lastTX[from] + 30 seconds),
                        "Cooldown in effect"
                    );
                    _lastTX[from] = block.timestamp;
                }
            }
        }

        if (antiSnipeBot) {
            if (
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerRouters[to] &&
                to != address(this) &&
                from != address(this)
            ) {
                require(tx.origin == to);
            }
            if (block.number <= firstLiveBlockNumber + 1) {
                isBlacklisted[tx.origin] = true;
            }
        }

        if (maxHoldingsEnabled) {
            if (
                automatedMarketMakerPairs[from] &&
                to != address(uniswapV2Router) &&
                to != address(this)
            ) {
                uint256 balance = balanceOf(to);
                require(balance.add(amount) <= maxHoldings);
            }
        }
    }

    function nukeLpTokenFromBuildup(uint256 _amount) external onlyOwner {
        _lpTokenNuke(_amount);
  }

    function _lpTokenNuke(uint256 _amount) private {
    // cannot nuke more than 30% of token supply in pool
        if (_amount > 0 && _amount <= (balanceOf(uniswapV2Pair) * 30) / 100) {
                if (_nukeRecipient == DEAD || _nukeRecipient == ZERO_ADDRESS) {
                    _burn(uniswapV2Pair, _amount);
                } else {
                    super._transfer(uniswapV2Pair, _nukeRecipient, _amount);
                 }
            
            IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
            pair.sync();
        }
  }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}