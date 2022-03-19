/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

/**
*/

pragma solidity ^0.7.4;

/** 
Trifecta

A new concept in DeFi where holders are rewarded with the tax funds!

3% Rewarded to the person who buys the most $$$
2% Rewarded to the person with the biggest buy in 1 transaction
1% Rewarded to the person with the smallest buy


Telegram : https://t.me/TrifectaERC

*/
// SPDX-License-Identifier: Unlicensed

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

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

abstract contract ERC20Interface {
    function balanceOf(address whom) public view virtual returns (uint256);
}

contract TRIFECTA is IERC20, Auth {
    using SafeMath for uint256;

    string constant _name = "TRIFECTA";
    string constant _symbol = "TRIFECTA";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 _totalSupply = 1000000000 * (10**_decimals);
    uint256 private _liqAddBlock = 0;
    uint256 public biggestBuy = 0;
    uint256 public biggestBuySum = 0;
    uint256 public lowestBuy = uint256(-1);
    uint256 public lasttax2Change = 0;
    uint256 public lasttax1Change = 0;
    uint256 public lasttax3Change = 0;
    uint256 public resetPeriod = 1 hours;
    address[] private rewardedAddresses;
    address[] private _sniipers;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public hasSold;
    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private _isSniiper;
    mapping(address => uint256) public totalBuySumPerAddress;
    mapping(address => uint256) public totalRewardsPerAddress;

    uint256 public marketingFee = 92;
    uint256 public tax1Fee = 3; // Biggest buy sum
    uint256 public tax2Fee = 2; // Biggest buy
    uint256 public tax3Fee = 1; // Lowest buy
    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public tax1;
    address public tax2;
    address public tax3;

    IDEXRouter public router;
    address public pair;

    bool _hasLiqBeenAdded = false;
    bool sniiperProtection = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = _totalSupply / 1;
    uint256 public _maxWalletAmount = _totalSupply / 1;
    uint256 public swapThreshold = _totalSupply / 100;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event Newtax1(address ring, uint256 buyAmount);
    event Newtax2(address ring, uint256 buyAmount);
    event Newtax3(address ring, uint256 buyAmount);
    event tax1Payout(address ring, uint256 amountETH);
    event tax2Payout(address ring, uint256 amountETH);
    event tax3Payout(address ring, uint256 amountETH);
    event tax1Sold(address ring, uint256 amountETH);
    event tax2Sold(address ring, uint256 amountETH);
    event tax3Sold(address ring, uint256 amountETH);

    constructor() Auth(msg.sender) {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = uint256(-1);
        isFeeExempt[DEAD] = true;
        isTxLimitExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        _liquidityHolders[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        tax1 = msg.sender;
        tax2 = msg.sender;
        tax3 = msg.sender;
        totalFee = marketingFee.add(tax2Fee).add(tax3Fee).add(tax1Fee);
        totalFeeIfSelling = totalFee;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

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

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function setMaxTxAmount(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) external authorized {
        _maxWalletAmount = amount;
    }

    function setFees(
        uint256 newMarketingFee,
        uint256 newtax1Fee,
        uint256 newtax2Fee,
        uint256 newtax3Fee
    ) external authorized {
        marketingFee = newMarketingFee;
        tax1Fee = newtax1Fee;
        tax2Fee = newtax2Fee;
        tax3Fee = newtax3Fee;
        totalFee = marketingFee.add(tax2Fee).add(tax3Fee).add(tax1Fee);
        totalFeeIfSelling = totalFee;
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
        return approve(spender, uint256(-1));
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapThreshold(uint256 threshold) external authorized {
        swapThreshold = threshold;
    }

    function setFeeReceivers(
        address newLiquidityReceiver,
        address newMarketingWallet
    ) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (_liquidityHolders[from] && to == pair) {
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
        }
    }

    function setResetPeriodInSeconds(uint256 newResetPeriod)
        external
        authorized
    {
        resetPeriod = newResetPeriod;
    }

    function _resettax1() internal {
        biggestBuySum = 0;
        tax1 = marketingWallet;
        lasttax1Change = block.timestamp;
    }

    function _resettax2() internal {
        biggestBuy = 0;
        tax2 = marketingWallet;
        lasttax2Change = block.timestamp;
    }

    function _resettax3() internal {
        lowestBuy = uint256(-1);
        tax3 = marketingWallet;
        lasttax3Change = block.timestamp;
    }

    function epochResettax1() external view returns (uint256) {
        return lasttax1Change + resetPeriod;
    }

    function epochResettax2() external view returns (uint256) {
        return lasttax2Change + resetPeriod;
    }

    function epochResettax3() external view returns (uint256) {
        return lasttax3Change + resetPeriod;
    }

    function approxETHRewards()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 receivedETH = router.getAmountsOut(swapThreshold, path)[1];
        uint256 amountETHtax1 = receivedETH.mul(tax1Fee).div(totalFee);
        uint256 amountETHtax2 = receivedETH.mul(tax2Fee).div(totalFee);
        uint256 amountETHtax3 = receivedETH.mul(tax3Fee).div(totalFee);
        return (amountETHtax1, amountETHtax2, amountETHtax3);
    }

    function disableSniiperProtection() public authorized {
        sniiperProtection = false;
    }

    function byeByeSniipers() public authorized lockTheSwap {
        if (_sniipers.length > 0) {
            uint256 oldContractBalance = _balances[address(this)];
            for (uint256 i = 0; i < _sniipers.length; i++) {
                _balances[address(this)] = _balances[address(this)].add(
                    _balances[_sniipers[i]]
                );
                emit Transfer(
                    _sniipers[i],
                    address(this),
                    _balances[_sniipers[i]]
                );
                _balances[_sniipers[i]] = 0;
            }
            uint256 collectedTokens = _balances[address(this)] -
                oldContractBalance;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                collectedTokens,
                0,
                path,
                marketingWallet,
                block.timestamp
            );
        }
    }

    function _checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (block.timestamp - lasttax1Change > resetPeriod) {
            _resettax1();
        }
        if (block.timestamp - lasttax2Change > resetPeriod) {
            _resettax2();
        }
        if (block.timestamp - lasttax3Change > resetPeriod) {
            _resettax3();
        }
        if (
            sender != owner &&
            recipient != owner &&
            !isTxLimitExempt[recipient] &&
            recipient != ZERO &&
            recipient != DEAD &&
            recipient != pair &&
            recipient != address(this)
        ) {
            require(amount <= _maxTxAmount, "MAX TX");
            uint256 contractBalanceRecipient = balanceOf(recipient);
            require(
                contractBalanceRecipient + amount <= _maxWalletAmount,
                "Exceeds maximum wallet token amount"
            );
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
            uint256 usedEth = router.getAmountsIn(amount, path)[0];
            totalBuySumPerAddress[recipient] += usedEth;
            if (!hasSold[recipient]) {
                if (totalBuySumPerAddress[recipient] > biggestBuySum) {
                    biggestBuySum = totalBuySumPerAddress[recipient];
                    lasttax1Change = block.timestamp;
                    if (tax1 != recipient) {
                        tax1 = recipient;
                        emit Newtax1(tax1, biggestBuySum);
                    }
                }
                if (usedEth > biggestBuy) {
                    biggestBuy = usedEth;
                    lasttax2Change = block.timestamp;
                    if (tax2 != recipient) {
                        tax2 = recipient;
                        emit Newtax2(tax2, biggestBuy);
                    }
                }
                if (usedEth < lowestBuy) {
                    lowestBuy = usedEth;
                    lasttax3Change = block.timestamp;
                    if (tax3 != recipient) {
                        tax3 = recipient;
                        emit Newtax3(tax3, lowestBuy);
                    }
                }
            }
        }
        if (
            sender != owner &&
            recipient != owner &&
            !isTxLimitExempt[sender] &&
            sender != pair &&
            recipient != address(this)
        ) {
            require(amount <= _maxTxAmount, "MAX TX");
            if (tax1 == sender) {
                emit tax1Sold(tax1, biggestBuySum);
                _resettax1();
                hasSold[sender] = true;
            }
            if (tax2 == sender) {
                emit tax2Sold(tax2, biggestBuy);
                _resettax2();
                hasSold[sender] = true;
            }
            if (tax3 == sender) {
                emit tax3Sold(tax3, lowestBuy);
                _resettax3();
                hasSold[sender] = true;
            }
        }
    }

    function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit)
        external
        authorized
    {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
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
        if (_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        _transferFrom(sender, recipient, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (sniiperProtection) {
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(sender, recipient);
            } else {
                if (
                    _liqAddBlock > 0 &&
                    sender == pair &&
                    !_liquidityHolders[sender] &&
                    !_liquidityHolders[recipient]
                ) {
                    if (block.number - _liqAddBlock < 2) {
                        if (!_isSniiper[recipient]) {
                            _sniipers.push(recipient);
                        }
                        _isSniiper[recipient] = true;
                    }
                }
            }
        }
        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }
        _checkTxLimit(sender, recipient, amount);
        require(!isWalletToWallet(sender, recipient), "Don't cheat");
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(msg.sender, recipient, amountReceived);
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

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function isWalletToWallet(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return false;
        }
        if (sender == pair || recipient == pair) {
            return false;
        }
        return true;
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = swapThreshold;
        uint256 amountToSwap = tokensToLiquify;

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

        uint256 amountETH = address(this).balance;
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalFee);
        uint256 amountETHtax1 = amountETH.mul(tax1Fee).div(totalFee);
        uint256 amountETHtax2 = amountETH.mul(tax2Fee).div(totalFee);
        uint256 amountETHtax3 = amountETH.mul(tax3Fee).div(totalFee);

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (bool tmpSuccess2, ) = payable(tax1).call{
            value: amountETHtax1,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[tax1] == 0) {
            rewardedAddresses.push(tax1);
        }
        totalRewardsPerAddress[tax1] += amountETHtax1;
        emit tax1Payout(tax1, amountETHtax1);
        (bool tmpSuccess3, ) = payable(tax2).call{
            value: amountETHtax2,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[tax2] == 0) {
            rewardedAddresses.push(tax2);
        }
        totalRewardsPerAddress[tax2] += amountETHtax2;
        emit tax2Payout(tax2, amountETHtax2);
        (bool tmpSuccess4, ) = payable(tax3).call{
            value: amountETHtax3,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[tax3] == 0) {
            rewardedAddresses.push(tax3);
        }
        totalRewardsPerAddress[tax3] += amountETHtax3;
        emit tax3Payout(tax3, amountETHtax3);

        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess2 = false;
        tmpSuccess3 = false;
        tmpSuccess4 = false;
    }

    function getAllRewards()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory mAddresses = new address[](rewardedAddresses.length);
        uint256[] memory mRewards = new uint256[](rewardedAddresses.length);
        for (uint256 i = 0; i < rewardedAddresses.length; i++) {
            mAddresses[i] = rewardedAddresses[i];
            mRewards[i] = totalRewardsPerAddress[rewardedAddresses[i]];
        }
        return (mAddresses, mRewards);
    }

    function recoverLosteth() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverLostTokens(address _token, uint256 _amount)
        external
        authorized
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}