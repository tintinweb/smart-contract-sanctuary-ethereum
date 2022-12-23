/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

/**
███████  █████  ███    ██ ████████  █████  
██      ██   ██ ████   ██    ██    ██   ██ 
███████ ███████ ██ ██  ██    ██    ███████ 
     ██ ██   ██ ██  ██ ██    ██    ██   ██ 
███████ ██   ██ ██   ████    ██    ██   ██ 
                                           
                                           
 ██████  ██ ███████ ████████ ███████       
██       ██ ██         ██    ██            
██   ███ ██ █████      ██    ███████       
██    ██ ██ ██         ██         ██       
 ██████  ██ ██         ██    ███████             
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexRouter {
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

interface IERC20Extended {
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

    event Transfer(
        address indexed recipient,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal owner;
    event OwnershipTransferred(address owner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
}

// main contract
contract SantaGiftsToken is IERC20Extended, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Santa Gifts";
    string private constant _symbol = "SG$";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    address public giftToken =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IDexRouter public router;
    address public pair;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public giftsFeeReceiver;

    uint256 _liquidityBuyFee = 1;
    uint256 _marketingBuyFee = 2;
    uint256 _giftsBuyFee = 1;
    uint256 _surpriseBuyFee = 1;

    uint256 _liquiditySellFee = 5;
    uint256 _marketingSellFee = 5;
    uint256 _giftsSellFee = 3;
    uint256 _surpriseSellFee = 2;

    uint256 _liquidityFeeCount;
    uint256 _marketingFeeCount;
    uint256 _giftsFeeCount;
    uint256 _surpriseFeeCount;

    uint256 public totalBuyFee = 5;
    uint256 public totalSellFee = 15;
    uint256 public feeDenominator = 100;

    uint256 public maxTxnAmount = (_totalSupply * 5) / 1000;
    uint256 public maxWalletAmount = (_totalSupply * 15) / 1000;
    uint256 public launchedAt;
    uint256 public snipingTime = 40 seconds;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExmpt;
    mapping(address => bool) public isWalletExmpt;
    mapping(address => bool) public isBot;
    address[] public buyers;

    bool public surpriseEnable;
    bool public swapEnabled;
    uint256 public swapThreshold = _totalSupply / 1_000;
    bool public trading; // once enable can't be disable afterwards

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    constructor() Ownable(msg.sender) {
        address router_ = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap v2
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = address(
            0xADF0a294D555D08CC33b5d884AbD5F5F2a0Df81c
        );
        giftsFeeReceiver = address(0xDbaa53EDD1196e1Dc1d800E5D154824e853807A8);

        router = IDexRouter(router_);
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[giftsFeeReceiver] = true;

        isLimitExmpt[msg.sender] = true;
        isLimitExmpt[address(this)] = true;

        isWalletExmpt[msg.sender] = true;
        isWalletExmpt[router_] = true;
        isWalletExmpt[pair] = true;
        isWalletExmpt[address(this)] = true;
        isWalletExmpt[ZERO] = true;
        isWalletExmpt[DEAD] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
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
        return _transferrecipient(msg.sender, recipient, amount);
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

        return _transferrecipient(sender, recipient, amount);
    }

    function _transferrecipient(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!isBot[sender], "Bot detected");
        if (!isLimitExmpt[sender] && !isLimitExmpt[recipient]) {
            require(amount <= maxTxnAmount, "Max limit exceeds");
            if (!trading) {
                require(
                    pair != sender && pair != recipient,
                    " trading is disable"
                );
            }
        }

        if (!isWalletExmpt[recipient]) {
            require(
                balanceOf(recipient).add(amount) < maxWalletAmount,
                "Max Wallet limit exceeds"
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        if (
            block.timestamp < launchedAt + snipingTime &&
            recipient != address(router)
        ) {
            if (pair == sender) {
                isBot[recipient] = true;
            } else if (pair == recipient) {
                isBot[sender] = true;
            }
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
            uint256 feeAmount;
            if (sender == pair) {
                feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
                setBuyAccFee(amount);
                buyers.push(recipient);
            } else {
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
                setSellAccFee(amount);
                if (!isLimitExmpt[sender] && surpriseEnable) {
                    buyersReward();
                }
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
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

    function takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function setBuyAccFee(uint256 _amount) internal {
        _liquidityFeeCount += _amount.mul(_liquidityBuyFee).div(feeDenominator);
        _marketingFeeCount += _amount.mul(_marketingBuyFee).div(feeDenominator);
        _giftsFeeCount += _amount.mul(_giftsBuyFee).div(feeDenominator);
        _surpriseFeeCount += _amount.mul(_surpriseBuyFee).div(feeDenominator);
    }

    function setSellAccFee(uint256 _amount) internal {
        _liquidityFeeCount += _amount.mul(_liquiditySellFee).div(
            feeDenominator
        );
        _marketingFeeCount += _amount.mul(_marketingSellFee).div(
            feeDenominator
        );
        _giftsFeeCount += _amount.mul(_giftsSellFee).div(feeDenominator);
        _surpriseFeeCount += _amount.mul(_surpriseSellFee).div(feeDenominator);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 totalFee = _liquidityFeeCount.add(_marketingFeeCount).add(
            _giftsFeeCount
        );

        uint256 amountToLiquify = swapThreshold
            .mul(_liquidityFeeCount)
            .div(totalFee)
            .div(2);

        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        _allowances[address(this)][address(router)] = _totalSupply;
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

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(_liquidityFeeCount.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(_liquidityFeeCount)
            .div(totalBNBFee)
            .div(2);
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }

        uint256 amountBNBgifts = amountBNB.mul(_giftsFeeCount).div(totalBNBFee);
        if (amountBNBgifts > 0) {
            address[] memory path1 = new address[](2);
            path1[0] = router.WETH();
            path1[1] = address(giftToken);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountBNBgifts
            }(0, path1, giftsFeeReceiver, block.timestamp);
        }

        uint256 amountBNBMarketing = amountBNB.mul(_marketingFeeCount).div(
            totalBNBFee
        );
        if (amountBNBMarketing > 0) {
            payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        }

        _liquidityFeeCount = 0;
        _marketingFeeCount = 0;
        _giftsFeeCount = 0;
    }

    function buyersReward() internal swapping {
        uint256 amountToSwap = _surpriseFeeCount;
        _allowances[address(this)][address(router)] = _totalSupply;
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

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 rewardForEach;
        if (buyers.length < 5) {
            rewardForEach = amountBNB / buyers.length;
            for (uint256 i; i < buyers.length; i++) {
                payable(buyers[i]).transfer(rewardForEach);
            }
        } else {
            rewardForEach = amountBNB / 5;
            for (uint256 i = buyers.length - 1; i >= buyers.length - 5; i--) {
                payable(buyers[i]).transfer(rewardForEach);
            }
        }

        _surpriseFeeCount = 0;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        isLimitExmpt[holder] = exempt;
    }

    function setIsWalletExempt(address holder, bool exempt) external onlyOwner {
        isWalletExmpt[holder] = exempt;
    }

    function removeStuckFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setMaxTxnAmount(uint256 _amount) external onlyOwner {
        maxTxnAmount = _amount;
    }

    function setMaxWalletAmount(uint256 _amount) external onlyOwner {
        maxWalletAmount = _amount;
    }

    function enableTrading() external onlyOwner {
        require(!trading, "already enabled");
        trading = true;
        swapEnabled = true;
        surpriseEnable = true;
        launchedAt = block.timestamp;
    }

    function setSurpriseEnable(bool _value) external onlyOwner {
        surpriseEnable = _value;
    }

    function setBuyFees(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _giftsFee,
        uint256 _surpriseFee,
        uint256 _feeDenominator
    ) public onlyOwner {
        _liquidityBuyFee = _liquidityFee;
        _marketingBuyFee = _marketingFee;
        _surpriseBuyFee = _giftsFee;
        _giftsBuyFee = _surpriseFee;
        totalBuyFee = _liquidityFee.add(_marketingFee).add(_giftsFee).add(
            _surpriseFee
        );
        feeDenominator = _feeDenominator;
    }

    function setSellFees(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _giftsFee,
        uint256 _surpriseFee,
        uint256 _feeDenominator
    ) public onlyOwner {
        _liquiditySellFee = _liquidityFee;
        _marketingSellFee = _marketingFee;
        _giftsSellFee = _giftsFee;
        _surpriseSellFee = _surpriseFee;
        totalSellFee = _liquidityFee.add(_marketingFee).add(_giftsFee).add(
            _surpriseFee
        );
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _giftsFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        giftsFeeReceiver = _giftsFeeReceiver;
    }

    function setGiftToken(address _giftToken) external onlyOwner {
        giftToken = _giftToken;
    }

    function addOrRemoveBots(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            require(
                accounts[i] != address(router) && pair != accounts[i],
                "cannot blacklist Dex"
            );
            isBot[accounts[i]] = value;
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
}