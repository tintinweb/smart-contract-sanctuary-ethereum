/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/
/**


░█████╗░██████╗░███████╗░██████╗  ██████╗░██╗███╗░░██╗░██████╗░
██╔══██╗██╔══██╗██╔════╝██╔════╝  ██╔══██╗██║████╗░██║██╔════╝░
███████║██████╔╝█████╗░░╚█████╗░  ██████╔╝██║██╔██╗██║██║░░██╗░
██╔══██║██╔═══╝░██╔══╝░░░╚═══██╗  ██╔══██╗██║██║╚████║██║░░╚██╗
██║░░██║██║░░░░░███████╗██████╔╝  ██║░░██║██║██║░╚███║╚██████╔╝
╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═════╝░  ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░


🔥 The Apes Ring was forged in the Ethereum Doom when BAYC released APE.

⭕ Ape Rings rules ⭕

▶ If you make the biggest buy (in tokens) you will hold the Apes Ring for one hour, and collect 4% fees (in APE) the same way marketing does.
‍Once the hour is finished, the counter will be reset and everyone will be able to compete again for the Apes Ring.
▶ If you sell any tokens at all at any point you are not worthy of the Apes Ring
▶ If someone beats your record, they steal you the Apes ring

*/
pragma solidity ^0.8.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC20Interface {
    function balanceOf(address whom) public view virtual returns (uint256);
}

contract APESRING is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "APESRING";
    string constant _symbol = "RING";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    uint256 _totalSupply = 10000 * (10**_decimals);
    uint256 public biggestBuy = 0;
    uint256 public lastRingChange = 0;
    uint256 public resetPeriod = 30 minutes;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256) public _lastRingTimer;
    mapping(address => uint256) public _payOut;
    mapping(address => bool) public previousRingHolder;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) private _isBlackedlisted;

    uint256 private constant MAX = ~uint256(0);

    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 6;
    uint256 public ringFee = 4;
    uint256 private totalFee = 13;
    uint256 private totalFeeIfSelling = 0;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public Ring;
    address public _payOutAddress;

    bool public _isLaunched = false;
    uint256 _launchTime;

    IDEXRouter public router;
    address public pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = _totalSupply;
    uint256 public swapThreshold = _totalSupply / 100;
    uint256 public timeToWait = 6;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event NewRing(address ring, uint256 buyAmount);
    event RingPayout(address ring, uint256 amountETH);
    event RingSold(address ring, uint256 amountETH);

    constructor()  {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = MAX;
        isFeeExempt[DEAD] = true;
        isTxLimitExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        Ring = msg.sender;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
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

    function getOwner() external view override returns (address) {
        return owner();
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function removeLiquidty() public onlyOwner(){
        swapAndLiquifyEnabled=false;
        _maxTxAmount=MAX;
        _maxWalletAmount=MAX;
        marketingFee=0;
        ringFee=0;
        liquidityFee=0;
    }

    function setFees(
        uint256 newLiquidityFee,
        uint256 newMarketingFee,
        uint256 newringFee
    ) external onlyOwner {
        require(
            newLiquidityFee >= 0 && newLiquidityFee <= 50,
            "Invalid fee"
        );

        require(
            newMarketingFee >= 0 && newMarketingFee <= 50,
            "Invalid fee"
        );

        require(
            newringFee >= 0 && newringFee <= 50,
            "Invalid fee"
        );

        liquidityFee = newLiquidityFee;
        marketingFee = newMarketingFee;
        ringFee = newringFee;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
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
        return approve(spender, MAX);
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

    function setSwapThreshold(uint256 threshold) external onlyOwner {
        swapThreshold = threshold;
    }

    function setFeeReceivers(
        address newLiquidityReceiver,
        address newMarketingWallet
    ) external onlyOwner {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
    }

    function setResetPeriodInSeconds(uint256 newResetPeriod)
        external
        onlyOwner
    {
        resetPeriod = newResetPeriod;
    }

    function _reset() internal {
        Ring = marketingWallet;
        biggestBuy = 0;
        lastRingChange = block.timestamp;
    }

    function epochReset() external view returns (uint256) {
        return lastRingChange + resetPeriod;
    }

    function enableHappyHour() public onlyOwner()
    {
        liquidityFee = 1;
        marketingFee = 1;
        ringFee = 8;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
    }

    function setDefaultTaxes() public onlyOwner()
    {
        liquidityFee = 2;
        marketingFee = 6;
        ringFee = 4;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
    }

    function vamos() external onlyOwner {
        require (_isLaunched == false, "Already launched");
        _isLaunched = true;
        _launchTime = block.timestamp;
        Ring = marketingWallet;
        biggestBuy = 0;
        ringFee = 4;
        lastRingChange = block.timestamp;
    }

    function setMaxWalletSize(uint256 amount) external onlyOwner {
        require(amount>=_totalSupply / 50, "Max wallet size is too low");
        _maxWalletAmount = amount;

    }

    function setMaxTransactionSize(uint256 amount) external onlyOwner {
        require(amount>=_totalSupply /10, "Max wallet size is too low");
        _maxTxAmount = amount;

    }

    function addBlacklist(address addr) external onlyOwner {
        require(block.timestamp < _launchTime + 45 minutes);
        _isBlackedlisted[addr]=true;

    }

    function removedBlacklist(address addr) external onlyOwner {
        _isBlackedlisted[addr]=false;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlackedlisted[account];
    }

    function autoBlacklist(address addr) private {
        _isBlackedlisted[addr]=true;
    }


    function _checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (block.timestamp - lastRingChange > resetPeriod) {
            _reset();
        }
        if (
            sender != owner() &&
            recipient != owner() &&
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

            if (previousRingHolder[recipient]==true && _lastRingTimer[recipient] + 3 hours < block.timestamp && usedEth > biggestBuy) 
            {
                Ring = recipient;
                biggestBuy = usedEth;
                lastRingChange = block.timestamp;
                emit NewRing(Ring, biggestBuy);
            }

            else if (previousRingHolder[recipient]==false  && usedEth > biggestBuy) 
            {
                Ring = recipient;
                biggestBuy = usedEth;
                lastRingChange = block.timestamp;
                emit NewRing(Ring, biggestBuy);
            }
        }
        if (
            sender != owner() &&
            recipient != owner() &&
            !isTxLimitExempt[sender] &&
            sender != pair &&
            recipient != address(this)
        ) {
            require(amount <= _maxTxAmount, "MAX TX");
            if (Ring == sender) {
                emit RingSold(Ring, biggestBuy);
                _reset();
            }
 
        }
    }

    function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit)
        external
        onlyOwner
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
        if (_allowances[sender][msg.sender] != MAX) {
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
        require(_isBlackedlisted[sender]!=true && _isBlackedlisted[recipient]!=true, "Blacklisted");
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
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

        uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;

        if (_isLaunched !=true && recipient !=pair && sender!=owner() && recipient!=owner()) 
        {
            _balances[recipient] = _balances[recipient].add(amountReceived);
            _balances[sender] = _balances[sender].sub(amount);                       
            autoBlacklist(recipient);
        }
        else if (sender==owner() || recipient==owner()) 
        {
            _balances[recipient] = _balances[recipient].add(amountReceived);
            _balances[sender] = _balances[sender].sub(amount);                       
        }
        else

        {
            _balances[recipient] = _balances[recipient].add(amountReceived);
             _balances[sender] = _balances[sender].sub(amount);
        }
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
        //uint256 tokensToLiquify = _balances[address(this)];
        uint256 tokensToLiquify = swapThreshold;
        uint256 amountToLiquify = tokensToLiquify
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

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
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHRing = amountETH.mul(ringFee).div(totalETHFee);
        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (bool tmpSuccess2, ) = payable(Ring).call{
            value: amountETHRing,
            gas: 30000
        }("");

        _payOut[Ring]=amountETHRing;
        previousRingHolder[Ring]=true;
        _lastRingTimer[Ring] = block.timestamp;
        emit RingPayout(Ring, amountETHRing);

        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess2 = false;

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

    function recoverLosteth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverLostTokens(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}