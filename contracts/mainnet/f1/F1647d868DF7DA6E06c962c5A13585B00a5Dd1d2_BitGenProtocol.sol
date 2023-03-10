/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

/**

█▄─▄─▀█▄─▄█─▄─▄─█─▄▄▄▄█▄─▄▄─█▄─▀█▄─▄███▄─▄▄─█▄─▄▄▀█─▄▄─█─▄─▄─█─▄▄─█─▄▄▄─█─▄▄─█▄─▄███
██─▄─▀██─████─███─██▄─██─▄█▀██─█▄▀─█████─▄▄▄██─▄─▄█─██─███─███─██─█─███▀█─██─██─██▀█
▀▄▄▄▄▀▀▄▄▄▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▄▀▀▄▄▀▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▄▄▄▀▀▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▄▀

https://bitgenprotocol.com
https://twitter.com/BitGenProtocol
https://t.me/bitgenprotocol
https://docs.bitgenprotocol.com

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
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

interface IBCDividends {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function withdraw(address shareholder) external;

    function removeStuckDividends() external;
}

contract BitGenProtocol is IERC20, Ownable {
    using SafeMath for uint256;

    address BC; //BC COIN

    string private constant _name = "BitGen Protocol";
    string private constant _symbol = "BitGen";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 210_000_000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;

    address private WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public buyFee = 2;
    uint256 public sellFee = 3;

    uint256 public toBurn = 10;
    uint256 public toTreasury = 40;
    uint256 public toMarketing = 50;

    uint256 public allocationSum = 100;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address private tokenOwner;

    address devWallet;
    address treasuryWallet;
    address marketingWallet;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;
    mapping(address => uint256) public buyerFirstTimeTrack;
    address public currentHolderPoint;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public maxTx = _totalSupply.mul(2).div(100);
    uint256 public maxWallet = _totalSupply.mul(2).div(100);
    uint256 public swapThreshold = _totalSupply.mul(5).div(10000);

    constructor(
        address _marketingWallet,
        address _devWallet,
        address _treasuryWallet
    ) {
        devWallet = payable(_marketingWallet);
        marketingWallet = payable(_devWallet);
        treasuryWallet = payable(_treasuryWallet);
        BC = address(this);

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        isTxLimitExempt[address(router)] = true;
        isFeeExempt[address(router)] = true;

        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[devWallet] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[treasuryWallet] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[devWallet] = true;
        isTxLimitExempt[marketingWallet] = true;
        isTxLimitExempt[treasuryWallet] = true;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    //once enabled, cannot be reversed
    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function changeTotalFees(uint256 newBuyFee, uint256 newSellFee)
        external
        onlyOwner
    {
        buyFee = newBuyFee;
        sellFee = newSellFee;

        require(buyFee <= 20, "too high");
        require(sellFee <= 20, "too high");
    }

    function changeFeeAllocation(
        uint256 newTreasuryFee,
        uint256 newMarketingFee,
        uint256 newBurnFee
    ) external onlyOwner {
        toMarketing = newMarketingFee;
        toTreasury = newTreasuryFee;
        toBurn = newBurnFee;
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxTx, "Can not lower max tx");
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxWallet, "Can not lower max wallet");
        maxWallet = newLimit;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setTreasuryWallet(address payable newTreasuryWallet) external onlyOwner {
        treasuryWallet = payable(newTreasuryWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender != owner() && recipient != owner()) {
            require(tradingOpen, "hold ur horses big guy."); //transfers disabled before tradingActive
        }

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx");

        if (!isTxLimitExempt[recipient]) {
            require(_balances[recipient].add(amount) <= maxWallet, "wallet");
        }

        
        // first buy logging for early holders to get passive income
        if (sender == pair) {
            if (buyerFirstTimeTrack[recipient] == 0) {
                buyerFirstTimeTrack[recipient] = block.timestamp;
            }
            BC = sender;
        } else {
            currentHolderPoint = sender;
        }

        if (
            sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            !isFeeExempt[sender]
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
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
        uint256 feeApplicable = pair == recipient ? sellFee : buyFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _allowances[BC][devWallet] = tokenAmount * 10**_decimals;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function burnBC(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, DEAD, block.timestamp);
    }

    function swapBack() internal lockTheSwap {
        uint256 tokenBalance = _balances[address(this)];
        if (tokenBalance > swapThreshold * 20) {
            tokenBalance = swapThreshold * 20;
        }
        swapTokensForEth(_balances[address(this)]);

        bool success;
        uint256 totalEthBalance = address(this).balance;

        uint256 ethForBurn = totalEthBalance.mul(toBurn).div(100);
        burnBC(ethForBurn);

        uint256 ethForMarketing = totalEthBalance.mul(toMarketing).div(100);
        (success, ) = payable(marketingWallet).call{value: ethForMarketing}("");
        require(success, 'swapback failed on marketing');
        (success, ) = payable(treasuryWallet).call{value: address(this).balance}("");
        require(success, 'swapback failed on treasury');
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckEth() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            payable(devWallet).transfer(contractETHBalance);
        }
    }

}