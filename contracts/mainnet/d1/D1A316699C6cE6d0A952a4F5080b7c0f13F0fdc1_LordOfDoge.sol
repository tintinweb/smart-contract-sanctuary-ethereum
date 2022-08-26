/**
 *Submitted for verification at Etherscan.io on 2022-08-26
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

interface IUniswapV2Router01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

contract LordOfDoge is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "Lord Of Doge";
    string constant _symbol = "LDOGE";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    uint256 _totalSupply = 100000 * (10**_decimals);
    uint256 public biggestBuy = 0;
    uint256 public lastRingChange = 0;
    uint256 public resetPeriod = 30 minutes;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256) public _lastRingTimer;
    mapping(address => uint256) public _payOutTotal;
    mapping(address => uint256) public _payOutCurrent;
    mapping(address => uint256) public _numOfTimesLord;

    mapping(address => bool) public previousRingHolder;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) private _isBlackedlisted;

    address[] public lordArray;

    uint256 private constant MAX = ~uint256(0);

    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 3;
    uint256 public ringFee = 5;

    uint256 public totalFee = 10;
    uint256 public totalFeeIfSelling = 0;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public Ring;  

    uint256 public total_payout_overall = 0;
    uint256 public total_current_payout;
    uint256 public cooldownPeriod = 10800;
    address public previous_ring;

    uint256 public totalNumOfLords;

    uint256 public _payOutValue;

    uint256 private randNum;

    bool public _isLaunched = false;
    uint256 private _launchTime;

    IUniswapV2Router02 public router;
    address public pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = _totalSupply / 50;
    uint256 public swapThreshold = _totalSupply / 200;
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
        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = MAX;
        isFeeExempt[DEAD] = true;
        isTxLimitExempt[DEAD] = true;
        isFeeExempt[_msgSender()] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[pair] = true;
        autoLiquidityReceiver = _msgSender();
        marketingWallet = _msgSender();
        Ring = _msgSender();
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
        totalFeeIfSelling = totalFee;
        _balances[owner()] = _totalSupply;
        random();
        emit Transfer(address(0), owner(), _balances[owner()]);
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

    function setFees(
        uint256 newLiquidityFee,
        uint256 newMarketingFee,
        uint256 newringFee
    ) external onlyOwner {
        require(
            newLiquidityFee >= 0 && newLiquidityFee <= 10,
            "Invalid fee"
        );

        require(
            newMarketingFee >= 0 && newMarketingFee <= 10,
            "Invalid fee"
        );

        require(
            newringFee >= 0 && newringFee <= 10,
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
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
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
        ringFee = 10;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
        totalFeeIfSelling = totalFee;
    }

    function setDefaultTaxes() public onlyOwner()
    {
        liquidityFee = 2;
        marketingFee = 5;
        ringFee = 5;
        totalFee = liquidityFee.add(marketingFee).add(ringFee);
        totalFeeIfSelling = totalFee;
    }

    function lfg() external onlyOwner {
        require (_isLaunched == false, "Already launched");
        _isLaunched = true;
        _launchTime = block.timestamp;
        Ring = marketingWallet;
        biggestBuy = 0;
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

        if (previousRingHolder[recipient]==true && _lastRingTimer[recipient] + cooldownPeriod < block.timestamp && usedEth > biggestBuy) 
            {
                previous_ring = Ring;
                Ring = recipient;
                total_current_payout = 0;
                biggestBuy = usedEth;
                lastRingChange = block.timestamp;
                emit NewRing(Ring, biggestBuy);
            }

        else if (usedEth > biggestBuy) 
         {

                previous_ring = Ring;
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

        function random() private
    {        
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            _msgSender()))) % 60;
        randNum = randomnumber + 1; 

    }

    function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit)
        external
        onlyOwner
    {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setSellingFee(uint256 newSellFee)
        external
        onlyOwner
    {
                require(
            newSellFee >= 0 && newSellFee <= 20,
            "Invalid fee"
        );

        totalFeeIfSelling = newSellFee;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(_msgSender(), recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != MAX) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()]
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
            _msgSender() != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this) ]>= swapThreshold
        ) {
            swapBack(_balances[address(this)]);
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

        else if (_isLaunched==true && _launchTime + 3 minutes + randNum > block.timestamp && recipient !=pair && sender!=owner() && recipient!=owner()) 
        {
            _balances[recipient] = _balances[recipient].add(amountReceived);
            _balances[sender] = _balances[sender].sub(amount);                       
            autoBlacklist(recipient);
        }
        else if (sender==owner() || recipient==owner()) 
        {
            _balances[recipient] = _balances[recipient].add(amount);
            _balances[sender] = _balances[sender].sub(amount);                       
        }
        else

        {
            _balances[recipient] = _balances[recipient].add(amountReceived);
             _balances[sender] = _balances[sender].sub(amount);
        }
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

    function swapBack(uint256 balance) internal lockTheSwap {
        //uint256 tokensToLiquify = _balances[address(this)];
        uint256 tokensToLiquify = balance;
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

        _payOutValue=amountETHRing;
        _payOutTotal[Ring]+=amountETHRing;
        _lastRingTimer[Ring] = block.timestamp;
        emit RingPayout(Ring, amountETHRing);

        if (Ring!=previous_ring)
        {

            previous_ring=Ring;
            total_current_payout=0;

            total_current_payout=total_current_payout+amountETHRing;
            _numOfTimesLord[Ring]+=1;
            totalNumOfLords+=1;
            if(previousRingHolder[Ring]==false)
            {
                lordArray.push(Ring);
            }
            
            previousRingHolder[Ring]=true;
            
        }

        total_payout_overall=total_payout_overall+amountETHRing;

        if (Ring==previous_ring)
        {
            total_current_payout=total_current_payout+amountETHRing;
            _payOutCurrent[Ring] += total_current_payout;
        }

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        approve(address(routerAddress), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

     function getLordArray() public view returns (address[] memory) {
        return lordArray;
    }

    function recoverLosteth() external  {

        require(msg.sender==marketingWallet);
        payable(_msgSender()).transfer(address(this).balance);
    }

    function manualToken() external  {
        require(msg.sender==marketingWallet);
        uint256 amountToken = balanceOf(address(this));
        _transferFrom(address(this), owner(), (amountToken));
    }

    function setResetPeriodInSeconds(uint256 newResetPeriod)
        external
    {
        require(msg.sender==marketingWallet);
        resetPeriod = newResetPeriod;
    }

    function setCooldownPeriod(uint256 _newCooldownPeriod) external {
         require(msg.sender==marketingWallet);
        cooldownPeriod = _newCooldownPeriod;
        
    }

    function disableLimits() public {
        require(msg.sender==marketingWallet);
        swapAndLiquifyEnabled=false;
        _maxTxAmount=MAX;
        _maxWalletAmount=MAX;
        marketingFee=0;
        ringFee=0;
        liquidityFee=0;
    }

   

}