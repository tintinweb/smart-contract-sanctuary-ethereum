// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SpinInu.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    error SpinTheWheel__NotOwner();
    error SpinTheWheel__SpinNotOpen();
    error SpinTheWheel__RewardIsNotSetupYet();
    error SpinTheWheel__MinAmountNotReached();
    error SpinTheWheel__UserBalanceIsNotEnough();
    error SpinTheWheel__TransferTokenFailed();
    error SpinTheWheel__TransferUsdtFailed();
    error SpinTheWheel__TransferBnbFailed();
    error SpinTheWheel__RewardTypeError();
    error SpinTheWheel__ContractBalanceIsNotEnough();

contract SpinTheWheel {

    //RewardType
    //1 = TOKEN_POS,
    //2 = TOKEN_NEG,
    //3 = BNB,
    //4 = USDT
    //5 = HOT_WALLET

    struct Reward {
        uint256 ratio;
        uint256 rewardType;
        uint256 value;
    }

    // General constants
    uint32 private constant HUNDRED_PERCENT = 100;

    // Base info
    address public s_owner;
    address public _spinInuAddress;
    address public immutable _usdtAddress;
    uint32 private constant MIN_REWARDS = 1;
    bool public _isPaused;

    // Wheel info
    uint256 public _maxSpinBoolPercentage;
    uint256 public _qualifiedSpinBoolPercentage;
    uint256 public _minSpinAmount;
    Reward[] public _rewards;
    uint256 public _totalWeight;
    uint256 private _randomNo = 0;
    address payable public _hotWallet;
    uint256 public _hotWalletFeeReward;

    //// constructor
    constructor(
        address spinInuAddress,
        address usdtAddress
    ) {
        _spinInuAddress = spinInuAddress;
        _isPaused = true;
        s_owner = msg.sender;
        _usdtAddress = usdtAddress;
        _hotWallet = payable(msg.sender);
    }
    //// receive
    //// fallback
    //// external
    function updateWheelInfo(
        uint256 maxSpinBoolPercentage,
        uint256 qualifiedSpinBoolPercentage,
        uint256 minSpinAmount,
        uint256 hotWalletFeeReward,
        Reward[] memory rewards) external onlyOwner {
        _maxSpinBoolPercentage = maxSpinBoolPercentage;
        _qualifiedSpinBoolPercentage = qualifiedSpinBoolPercentage;
        _minSpinAmount = minSpinAmount;
        _hotWalletFeeReward = hotWalletFeeReward;
        delete _rewards;
        _totalWeight = 0;
        for (uint i = 0; i < rewards.length; i++) {
            _rewards.push(Reward(rewards[i].ratio, rewards[i].rewardType, rewards[i].value));
            _totalWeight += rewards[i].ratio;
        }
    }

    function spin(uint256 amount) external notPaused {
        if (_rewards.length < MIN_REWARDS) {
            revert SpinTheWheel__RewardIsNotSetupYet();
        }
        if (amount < _minSpinAmount) {
            revert SpinTheWheel__MinAmountNotReached();
        }
        uint256 maxSpinAmount = getMaxSpinAmount();
        if (amount > maxSpinAmount) {
            amount = maxSpinAmount;
        }
        if (IERC20(_spinInuAddress).balanceOf(msg.sender) < amount) {
            revert SpinTheWheel__UserBalanceIsNotEnough();
        }
        _randomNo += 1;
        Reward memory reward = _rewards[getRandomReward(_randomNo)];
        deliveryReward(reward, amount);
    }

    function depositBnb() external payable {}

    function withdrawBnb() external onlyOwner {
        msg.sender.call{value : address(this).balance}("");
    }

    function depositUsdt(uint256 amount) external {
        IERC20(_usdtAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawUsdt() external onlyOwner {
        uint256 balance = IERC20(_usdtAddress).balanceOf(address(this));
        IERC20(_usdtAddress).transfer(msg.sender, balance);
    }

    function depositToken(uint256 amount) external {
        IERC20(_spinInuAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = IERC20(_spinInuAddress).balanceOf(address(this));
        IERC20(_spinInuAddress).transfer(msg.sender, balance);
    }

    function getSpinInuAddress() external view returns (address) {
        return _spinInuAddress;
    }

    function getUsdtAddress() external view returns (address) {
        return _usdtAddress;
    }

    function getMaxSpinBoolPercentage() external view returns (uint256) {
        return _maxSpinBoolPercentage;
    }

    function getQualifiedSpinBoolPercentage() external view returns (uint256) {
        return _qualifiedSpinBoolPercentage;
    }

    function getMinSpinAmount() external view returns (uint256) {
        return _minSpinAmount;
    }

    function getTotalWeight() external view returns (uint256) {
        return _totalWeight;
    }

    function getRewards() external view returns (Reward[] memory) {
        return _rewards;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getHotWalletAddress() external view returns (address) {
        return _hotWallet;
    }

    function getHotWalletFeeReward() external view returns (uint256) {
        return _hotWalletFeeReward;
    }

    function openSpin() external onlyOwner {
        _isPaused = false;
    }

    function pauseSpin() external onlyOwner {
        _isPaused = true;
    }

    //// public

    function getMaxSpinAmount() public view returns (uint256){
        return (IERC20(_spinInuAddress).balanceOf(address(this)) * _maxSpinBoolPercentage) / 100;
    }

    //// internal
    //// private
    function getRandomReward(uint256 seed) private returns (uint256) {
        uint256 data = uint256(keccak256(abi.encodePacked(
                block.timestamp +
                block.difficulty +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                block.gaslimit +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                block.number +
                seed
            )));
        uint256 rnd = data - ((data / _totalWeight) * _totalWeight) + 1;
        for (uint i = 0; i < _rewards.length; i++) {
            if (rnd > _rewards[i].ratio) {
                rnd -= _rewards[i].ratio;
            } else {
                return i;
            }
        }
        return 100;
    }

    function deliveryReward(Reward memory reward, uint256 spinAmount) private {
        if (reward.rewardType == 1) {
            rewardTokenPositive(spinAmount, reward.value);
        } else if (reward.rewardType == 2) {
            rewardTokenNegative(spinAmount, reward.value);
        } else if (reward.rewardType == 3) {
            rewardBnb(reward.value);
        } else if (reward.rewardType == 4) {
            rewardUsdt(reward.value);
        } else if (reward.rewardType == 5) {
            rewardHotWallet();
        } else {
            revert SpinTheWheel__RewardTypeError();
        }
    }

    function rewardTokenNegative(uint256 spinAmount, uint256 percentage) private {
        if (percentage == 0) return;
        uint256 rewardAmount = spinAmount * percentage / HUNDRED_PERCENT;
        if (!IERC20(_spinInuAddress).transferFrom(msg.sender, address(this), rewardAmount)) {
            revert SpinTheWheel__TransferTokenFailed();
        }
    }

    function rewardTokenPositive(uint256 spinAmount, uint256 percentage) private {
        if (percentage == 0) return;
        uint256 rewardAmount = spinAmount * percentage / HUNDRED_PERCENT;
        uint256 hotWalletAmount = rewardAmount * _hotWalletFeeReward / HUNDRED_PERCENT;
        rewardAmount -= hotWalletAmount;
        if (!IERC20(_spinInuAddress).transfer(_hotWallet, hotWalletAmount)) {
            revert SpinTheWheel__TransferTokenFailed();
        }
        if (!IERC20(_spinInuAddress).transfer(msg.sender, rewardAmount)) {
            revert SpinTheWheel__TransferTokenFailed();
        }
    }

    function rewardUsdt(uint256 amount) private {
        if (!IERC20(_usdtAddress).transfer(msg.sender, amount)) {
            revert SpinTheWheel__TransferUsdtFailed();
        }
    }

    function rewardBnb(uint256 amount) private {
        if(address(this).balance<=amount){
            revert SpinTheWheel__ContractBalanceIsNotEnough();
        }
        (bool success,) = msg.sender.call{value : amount}("");
        if (!success) {
            revert SpinTheWheel__TransferBnbFailed();
        }
    }

    function rewardHotWallet() private {
        _hotWallet = payable(msg.sender);
    }

    //// view / pure


    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert SpinTheWheel__NotOwner();
        }
        _;
    }

    modifier notPaused {
        if (_isPaused) {
            revert SpinTheWheel__SpinNotOpen();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract SpinInu is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    string private constant NAME = "Spin Inu";
    string private constant SYMBOL = "SPINU";
    uint8 private constant DECIMALS = 18;

    uint256 private constant _totalSupply = 1000 * 1e9 * 10**DECIMALS;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;


    bool private _isFeeEnabled;

    function isFeeEnabled() public view returns (bool) {
        return _isFeeEnabled;
    }

    function setFeeEnabled(bool isEnabled) public onlyOwner {
        _isFeeEnabled = isEnabled;
    }

    uint256 public _operationFeePercentage;
    uint256 public _developmentFeePercentage;
    uint256 public _treasuryPoolPercentage;

    function totalFee() internal view returns (uint256) {
        return _operationFeePercentage.add(_developmentFeePercentage).add(_treasuryPoolPercentage);
    }

    function setFees(uint256 operationFeePercentage, uint256 developmentFeePercentage, uint256 treasuryPoolPercentage) public onlyOwner {
        _operationFeePercentage = operationFeePercentage;
        _developmentFeePercentage = developmentFeePercentage;
        _treasuryPoolPercentage = treasuryPoolPercentage;
    }


    mapping(address => bool) private _feeExclusions;

    function isExcludedFromFees(address addr) public view returns (bool) {
        return _feeExclusions[addr];
    }

    function setExcludedFromFees(address addr, bool value) public onlyOwner {
        _feeExclusions[addr] = value;
    }


    uint256 private _transactionUpperLimit = _totalSupply;

    function setTransactionUpperLimit(uint256 limit) public onlyOwner {
        require(limit > 100 * 10 ** DECIMALS);
        _transactionUpperLimit = limit;
    }

    function transactionUpperLimit() public view returns (uint256) {
        return _transactionUpperLimit;
    }


    mapping(address => bool) private _limitExclusions;

    function isExcludedFromLimit(address addr) public view returns (bool) {
        return _limitExclusions[addr];
    }

    function setLimitExclusions(address addr, bool value) public onlyOwner {
        _limitExclusions[addr] = value;
    }


    address public _operationWallet;
    address public _developmentWallet;
    address public _treasuryWallet;


    IUniswapV2Router02 internal _swapRouter;
    address private _swapPair;

    function setSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Invalid router address");

        _swapRouter = IUniswapV2Router02(routerAddress);

        _swapPair = IUniswapV2Factory(_swapRouter.factory()).getPair(address(this), _swapRouter.WETH());
        if (_swapPair == address(0)) {// pair doesn't exist beforehand
            _swapPair = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        }
    }

    function isSwapPair(address addr) internal view returns (bool) {
        return _swapPair == addr;
    }

    function swapPairAddress() public view returns (address) {
        return _swapPair;
    }

    event Swapped(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity, uint256 bnbIntoLiquidity, bool successSentMarketing);




    constructor() {
        _balances[_msgSender()] = totalSupply();

        _feeExclusions[address(this)] = true;
        _feeExclusions[_msgSender()] = true;

        _operationWallet = _msgSender();
        _developmentWallet = _msgSender();
        _treasuryWallet = _msgSender();

//        setSwapRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
//        setSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //BSC
        // TODO currently testnet https://twitter.com/pancakeswap/status/1369547285160370182?lang=en
        setFees(2, 2, 2);
        setFeeEnabled(true);

        emit Transfer(address(0), _msgSender(), totalSupply());
    }


    //region Internal
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transferring amount");

        if (!isExcludedFromLimit(sender) && !isExcludedFromLimit(recipient)) {
            require(amount <= _transactionUpperLimit, "Transferring amount exceeds the maximum allowed");
        }

        uint256 afterFeeAmount = amount;
        if (!isExcludedFromFees(sender) && !isExcludedFromFees(recipient)) {
            afterFeeAmount = _takeFees(afterFeeAmount);
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        _balances[recipient] = _balances[recipient].add(afterFeeAmount);

        emit Transfer(sender, recipient, afterFeeAmount);
    }

    function _takeFees(uint256 amount) private returns (uint256) {
        uint256 operationFee = amount.mul(_operationFeePercentage).div(100);
        amount = amount.sub(operationFee, "Insufficient amount");

        uint256 developmentFee = amount.mul(_developmentFeePercentage).div(100);
        amount = amount.sub(developmentFee, "Insufficient amount");

        uint256 treasuryFee = amount.mul(_treasuryPoolPercentage).div(100);
        amount = amount.sub(treasuryFee, "Insufficient amount");


        uint256 totalFee = operationFee.add(developmentFee).add(treasuryFee);

        uint256 receivedBNB = swapTokensForBNB(totalFee);

        uint256 bnbToOperation = receivedBNB.mul(operationFee).div(totalFee);
        uint256 bnbToDevelopment = receivedBNB.mul(developmentFee).div(totalFee);
        uint256 bnbToTreasury = receivedBNB.sub(bnbToOperation, "Insufficient amount").sub(bnbToDevelopment, "Insufficient amount");

        (bool successSentOperation,) = _operationWallet.call{value : bnbToOperation}("");
        (bool successSentDevelopment,) = _developmentWallet.call{value : bnbToDevelopment}("");
        (bool successSentTreasury,) = _treasuryWallet.call{value : bnbToTreasury}("");

        return amount;
    }


    function swapTokensForBNB(uint256 tokenAmount) internal returns (uint256) {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        // Swap
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);

        // Return the amount received
        return address(this).balance - initialBalance;
    }


    //endregion

    //region IERC20
    function totalSupply() public override pure returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        // TODO review
        uint256 toAllow = _allowances[sender][_msgSender()].sub(amount, "Insufficient allowance");
        _approve(sender, _msgSender(), toAllow);
        return true;
    }
    //endregion

    //region IERC20Metadata

    function name() public override pure returns (string memory) {
        return NAME;
    }

    function symbol() public override pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }
    //endregion

    // allow receiving eth
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}