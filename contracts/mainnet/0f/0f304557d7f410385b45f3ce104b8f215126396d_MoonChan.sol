/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

/*                                         
MoonChan                                                                                                                  
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "NOT AN OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface Irouter {
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

contract MoonChan is IERC20, Ownable {
    using SafeMath for uint256;

    address public WETH;
    address public staking;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "MoonChan";
    string constant _symbol = "MC";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1 * 10**6 * (10**_decimals);
    uint256 public maxTxAmount = _totalSupply.mul(10).div(1000); // 1%
    uint256 public maxHoldingLimit = _totalSupply.mul(10).div(1000); // 1%

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isExcludedFromMaxHold;
    mapping(address => bool) isSniper;

    uint256 liquidityFee = 20;
    uint256 teamFee = 10;
    uint256 marketFee = 20;
    uint256 totalFee = 50;
    uint256 feeDenominator = 1000;
    uint256 maxFee = 150;
    bool public enableAutoBlacklist;
    uint256 public gasLimit = 200000000000; // gas limit threshold for blacklist / 1 GWEI = 1,000,000,000

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public teamFeeReceiver;

    uint256 targetLiquidity = 45;
    uint256 targetLiquidityDenominator = 100;

    Irouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    uint256 antiSnipingTime = 60 seconds;

    uint256 distributorGas = 500000;

    bool public swapEnabled;
    bool public tradingOpen;

    uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _market,
        address _teamFee,
        address newOwner
    ) Ownable(newOwner) {
        router = Irouter(_router);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[newOwner] = true;
        isExcludedFromMaxHold[newOwner] = true;
        isExcludedFromMaxHold[address(this)] = true;
        isExcludedFromMaxHold[pair] = true;
        isTxLimitExempt[newOwner] = true;
        autoLiquidityReceiver = newOwner;
        marketingFeeReceiver = _market;
        teamFeeReceiver = _teamFee;

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[newOwner] = _totalSupply;

        emit Transfer(address(0), newOwner, _totalSupply);
    }

    receive() external payable {}

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
        return approve(spender, _totalSupply);
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
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!isSniper[sender], "Sniper detected");
        require(!isSniper[recipient], "Sniper detected");
        if (!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            // trading disable till launch
            if (!tradingOpen) {
                require(
                    sender != pair && recipient != pair,
                    "Trading is not enabled yet"
                );
            }
            // antibot
            if (
                block.timestamp < launchedAtTimestamp + antiSnipingTime &&
                sender != address(router)
            ) {
                if (sender == pair) {
                    isSniper[recipient] = true;
                } else if (recipient == pair) {
                    isSniper[sender] = true;
                }
            }

            require(amount <= maxTxAmount, "TX Limit Exceeded");
        }

        bool isBuy = sender == pair || sender == address(router);
        bool isSell = recipient == pair || recipient == address(router);

        if (isBuy || isSell) {
            if (tx.gasprice > gasLimit && enableAutoBlacklist) {
                if (isBuy) {
                    isSniper[recipient] = true;
                    emit antiBotBan(recipient);
                } else if (isSell) {
                    isSniper[sender] = true;
                    emit antiBotBan(sender);
                }
                return false;
            }
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != pair && recipient != pair)
        ) {
            amountReceived = amount;
        } else {
            amountReceived = takeFee(sender, amount);
        }

        // Check for max holding of receiver
        if (!isExcludedFromMaxHold[recipient]) {
            require(
                _balances[recipient] + amountReceived <= maxHoldingLimit,
                "Max holding limit exceeded"
            );
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function stakingReward(address _to, uint256 _amount) external {
        require(msg.sender == staking, "Not authorized");
        _mint(_to, _amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(marketFee).div(totalETHFee);
        uint256 amountETHBuyback = amountETH.mul(teamFee).div(totalETHFee);

        payable(marketingFeeReceiver).transfer(amountETHMarketing);
        payable(teamFeeReceiver).transfer(amountETHBuyback);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
        tradingOpen = true;
        swapEnabled = true;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    function withdrawFunds(address _user, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        payable(_user).transfer(_amount);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsExcludedFromMaxHold(address holder, bool excluded)
        external
        onlyOwner
    {
        isExcludedFromMaxHold[holder] = excluded;
    }

    //Sets new gas limit threshold for blacklist.
    function setGasLimit(uint256 _limit) external onlyOwner {
        gasLimit = _limit;
    }

    function setEnableAutoBlacklist(bool _status) external onlyOwner {
        enableAutoBlacklist = _status;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _teamFee,
        uint256 _marketFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        teamFee = _teamFee;
        marketFee = _marketFee;
        totalFee = _liquidityFee.add(_teamFee).add(_marketFee);
        require(totalFee <= maxFee, "can't set fee more than 25%");
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _teamFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        onlyOwner
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setMaxHoldingLimit(uint256 _limit) external onlyOwner {
        maxHoldingLimit = _limit;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    function setRoute(Irouter _router, address _pair) external onlyOwner {
        require(
            address(_router) != address(0),
            "Router adress cannot be address zero"
        );
        require(_pair != address(0), "Pair adress cannot be address zero");
        router = _router;
        pair = _pair;
    }

    function setStaking(address _stakingAddr) external onlyOwner {
        staking = _stakingAddr;
    }

    function addSniperInList(address _account) external onlyOwner {
        require(_account != address(router), "We can not blacklist router");
        require(!isSniper[_account], "Sniper already exist");
        isSniper[_account] = true;
    }

    function removeSniperFromList(address _account) external onlyOwner {
        require(isSniper[_account], "Not a sniper");
        isSniper[_account] = false;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event antiBotBan(address indexed value);
}