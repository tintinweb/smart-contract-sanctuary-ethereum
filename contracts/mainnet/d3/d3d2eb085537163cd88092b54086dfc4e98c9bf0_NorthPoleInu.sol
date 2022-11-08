/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

/**

As the Christmas META advances, a long staff thumps the ground, unleashing a gift for santas, rudolphs and hodlers alike.

The North Pole Inu ($NORTHPOLE) contract is constructed so that the success of the project is shared with the most dedicated.
The smart contract will be able to pick out transactions done from the previous hour to decide who gets to become the next SANTA and RUDOLPH. 

8% Total Tax
3% SANTA Payment
1% RUDOLPH Payment
4% Marketing & Development

SANTA    - Given to the Biggest Buyer in one transaction 
RUDOLPH  - Given to the Biggest Buyer accumulated

See more details on our website: https://www.northpoleinu.com/

Website: https://www.northpoleinu.com/
Telegram: https://t.me/northpoleinuportal
Twitter: https://twitter.com/northpoleinu

*/
// SPDX-License-Identifier: Unlicensed

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

contract NorthPoleInu is IERC20, Auth {
    using SafeMath for uint256;

    string constant _name = "North Pole Inu";
    string constant _symbol = "NORTHPOLE";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 _totalSupply = 10000000 * (10**_decimals);
    uint256 private _liqAddBlock = 0;
    uint256 public biggestBuy = 0;
    uint256 public biggestBuySum = 0;
    uint256 public lowestBuy = uint256(-1);
    uint256 public lastsantaChange = 0;
    uint256 public lastrudolphChange = 0;
    uint256 public lastEmeraldChange = 0;
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

    uint256 public marketingFee = 4; 
    uint256 public rudolphFee = 1; // Biggest buy sum
    uint256 public santaFee = 3; // Biggest buy
    uint256 public emeraldFee = 0; // Lowest buy
    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 8;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public rudolph;
    address public santa;
    address public Emerald;

    IDEXRouter public router;
    address public pair;

    bool _hasLiqBeenAdded = false;
    bool sniiperProtection = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = _totalSupply / 200;
    uint256 public _maxWalletAmount = _totalSupply / 200;
    uint256 public swapThreshold = _totalSupply / 1000;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event Newrudolph(address ring, uint256 buyAmount);
    event Newsanta(address ring, uint256 buyAmount);
    event NewEmerald(address ring, uint256 buyAmount);
    event rudolphPayout(address ring, uint256 amountETH);
    event santaPayout(address ring, uint256 amountETH);
    event EmeraldPayout(address ring, uint256 amountETH);
    event rudolphSold(address ring, uint256 amountETH);
    event santaSold(address ring, uint256 amountETH);
    event EmeraldSold(address ring, uint256 amountETH);

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
        rudolph = msg.sender;
        santa = msg.sender;
        Emerald = msg.sender;
        totalFee = marketingFee.add(santaFee).add(emeraldFee).add(rudolphFee);
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
        uint256 newrudolphFee,
        uint256 newsantaFee,
        uint256 newEmeraldFee
    ) external authorized {
        marketingFee = newMarketingFee;
        rudolphFee = newrudolphFee;
        santaFee = newsantaFee;
        emeraldFee = newEmeraldFee;
        totalFee = marketingFee.add(santaFee).add(emeraldFee).add(rudolphFee);
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

    function _resetrudolph() internal {
        biggestBuySum = 0;
        rudolph = marketingWallet;
        lastrudolphChange = block.timestamp;
    }

    function _resetsanta() internal {
        biggestBuy = 0;
        santa = marketingWallet;
        lastsantaChange = block.timestamp;
    }

    function _resetEmerald() internal {
        lowestBuy = uint256(-1);
        Emerald = marketingWallet;
        lastEmeraldChange = block.timestamp;
    }

    function epochResetrudolph() external view returns (uint256) {
        return lastrudolphChange + resetPeriod;
    }

    function epochResetsanta() external view returns (uint256) {
        return lastsantaChange + resetPeriod;
    }

    function epochResetEmerald() external view returns (uint256) {
        return lastEmeraldChange + resetPeriod;
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
        uint256 amountETHrudolph = receivedETH.mul(rudolphFee).div(totalFee);
        uint256 amountETHsanta = receivedETH.mul(santaFee).div(totalFee);
        uint256 amountETHEmerald = receivedETH.mul(emeraldFee).div(totalFee);
        return (amountETHrudolph, amountETHsanta, amountETHEmerald);
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
        if (block.timestamp - lastrudolphChange > resetPeriod) {
            _resetrudolph();
        }
        if (block.timestamp - lastsantaChange > resetPeriod) {
            _resetsanta();
        }
        if (block.timestamp - lastEmeraldChange > resetPeriod) {
            _resetEmerald();
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
                    lastrudolphChange = block.timestamp;
                    if (rudolph != recipient) {
                        rudolph = recipient;
                        emit Newrudolph(rudolph, biggestBuySum);
                    }
                }
                if (usedEth > biggestBuy) {
                    biggestBuy = usedEth;
                    lastsantaChange = block.timestamp;
                    if (santa != recipient) {
                        santa = recipient;
                        emit Newsanta(santa, biggestBuy);
                    }
                }
                if (usedEth < lowestBuy) {
                    lowestBuy = usedEth;
                    lastEmeraldChange = block.timestamp;
                    if (Emerald != recipient) {
                        Emerald = recipient;
                        emit NewEmerald(Emerald, lowestBuy);
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
            if (rudolph == sender) {
                emit rudolphSold(rudolph, biggestBuySum);
                _resetrudolph();
                hasSold[sender] = true;
            }
            if (santa == sender) {
                emit santaSold(santa, biggestBuy);
                _resetsanta();
                hasSold[sender] = true;
            }
            if (Emerald == sender) {
                emit EmeraldSold(Emerald, lowestBuy);
                _resetEmerald();
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
        uint256 amountETHrudolph = amountETH.mul(rudolphFee).div(totalFee);
        uint256 amountETHsanta = amountETH.mul(santaFee).div(totalFee);
        uint256 amountETHEmerald = amountETH.mul(emeraldFee).div(totalFee);

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (bool tmpSuccess2, ) = payable(rudolph).call{
            value: amountETHrudolph,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[rudolph] == 0) {
            rewardedAddresses.push(rudolph);
        }
        totalRewardsPerAddress[rudolph] += amountETHrudolph;
        emit rudolphPayout(rudolph, amountETHrudolph);
        (bool tmpSuccess3, ) = payable(santa).call{
            value: amountETHsanta,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[santa] == 0) {
            rewardedAddresses.push(santa);
        }
        totalRewardsPerAddress[santa] += amountETHsanta;
        emit santaPayout(santa, amountETHsanta);
        (bool tmpSuccess4, ) = payable(Emerald).call{
            value: amountETHEmerald,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[Emerald] == 0) {
            rewardedAddresses.push(Emerald);
        }
        totalRewardsPerAddress[Emerald] += amountETHEmerald;
        emit EmeraldPayout(Emerald, amountETHEmerald);

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