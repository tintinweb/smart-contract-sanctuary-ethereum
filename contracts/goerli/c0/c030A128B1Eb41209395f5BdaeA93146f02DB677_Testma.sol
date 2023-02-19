/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
contract DiscounterRole {
    using Roles for Roles.Role;

    event DiscounterAdded(address indexed account);
    event DiscounterRemoved(address indexed account);

    Roles.Role private _discounters;

    constructor() {
        _addDiscounter(msg.sender);
    }

    modifier onlyDiscounter() {
        require(
            isDiscounter(msg.sender),
            "DiscounterRole: caller does not have the Discounter role"
        );
        _;
    }

    function isDiscounter(address account) public view returns (bool) {
        return _discounters.has(account);
    }

    function renounceDiscounter() public {
        _removeDiscounter(msg.sender);
    }

    function _addDiscounter(address account) internal {
        _discounters.add(account);
        emit DiscounterAdded(account);
    }

    function _removeDiscounter(address account) internal {
        _discounters.remove(account);
        emit DiscounterRemoved(account);
    }
}
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
interface IDEXRouter {
    function factory() external returns (address);

    function WETH() external returns (address);

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
interface ILiquidityProvider {
    function sync() external;
}
contract Testma is ERC20Detailed, Ownable, DiscounterRole {
    using SafeMath for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogFeesChanged(
        uint256 liquidityFee,
        uint256 treasury,
        uint256 riskFreeValue,
        uint256 sellFee,
        uint256 totalFee
    );
    event LogGonSwapThresholdChanged(uint256 gonSwapThreshold);
    event LogSwapBackPaused(bool paused);
    event RouterAddressChanged(address routerAddress);
    event DecreaseRebaseRate(uint256 indexed rebaseRate);

    bool public initialDistributionFinished;

    mapping(address => bool) allowTransfer;
    mapping(address => bool) _isFeeExempt;

    /**
     * @dev fee discounts mapping for future products implementations
     */
    mapping(address => uint256) _feeDiscount;
    mapping(address => uint256) _discountEnds;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                allowTransfer[msg.sender],
            "Protocol running in IDO mode"
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0), "Zero address recipient");
        _;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        1 * 10**7 * 10**DECIMALS;

    uint256 public liquidityFee = 2;
    uint256 public treasury = 3;
    uint256 public riskFreeValue = 3;
    uint256 public sellFee = 2;
    uint256 public totalFee = 8;
    uint256 public constant feeDenominator = 100;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public constant autoLiquidityAddress = 0x09312b395fB97885868313Ec8cc632077e9C39Be;
    address public constant treasuryAddress = 0x7590c0e9f30517903b071bA37efb2287Ac8Afe99;
    address public constant riskFreeValueAddress = 0x44280680A9C6D42AcBD035E4D3ef66ff7862F327;
    address public operationsAddress;
    address public routerContractAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint256 private targetLiquidity = 50;
    uint256 private targetLiquidityDenominator = 100;

    ILiquidityProvider public pairContract;
    IDEXRouter public router;
    address public liquidityProviderAddress;

    bool public inSwap;
    modifier swapping() {
        require(inSwap == false, 'no reentrancy');
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 public gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    uint256 private constant MAX_SUPPLY = type(uint256).max;

    bool public manualSwapEnabled;
    uint256 public _lastManualSwapTime;
    bool public swapBackPaused;

    bool public _autoRebase = false;
    uint256 public startedTrading; //timestamp of start of trading
    uint256 public lastRebasedTime;
    uint256 public rebaseRate = 2229;
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;

    constructor() ERC20Detailed("Testma Token", "TESTMA", uint8(DECIMALS)) {

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryAddress] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // start contract in "Distribution period"
        initialDistributionFinished = false;

        // makes the treasury wallet, the RFV and the contract itself FeeExempt
        _isFeeExempt[treasuryAddress] = true;
        _isFeeExempt[riskFreeValueAddress] = true;
        _isFeeExempt[address(this)] = true;

        //renounce discounter role, only owner will be able to add new ones
        renounceDiscounter();

        //gives the treasury the power to transfer tokens before the IO finishes
        //this will be necessary to move funds around for the distribution
        allowTransfer[treasuryAddress] = true;

        //setup Sushi router
        router = IDEXRouter(routerContractAddress);
        // Sushi mainnet 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        // Sushi testnet 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506

        liquidityProviderAddress = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        pairContract = ILiquidityProvider(liquidityProviderAddress);

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[address(this)][liquidityProviderAddress] = uint256(
            -1
        );

        //multisig is the owner on creation,
        //this will be renounced and give to timelock contract
        _transferOwnership(treasuryAddress);

        // mint all $TESTMA to treasury wallet
        emit Transfer(address(0x0), treasuryAddress, _totalSupply);
    }

    function updateBlacklist(address _user, bool _flag) external onlyOwner {
        blacklist[_user] = _flag;
    }

    function _rebase() private {
        uint256 deltaTime = block.timestamp - lastRebasedTime;
        uint256 times = deltaTime.div(15 minutes);
        uint256 epoch = block.timestamp.sub(startedTrading).div(15 minutes);

        for (uint8 i = 0; i < times; i++) {
            _totalSupply = _totalSupply.mul(10**7 + rebaseRate).div(10**7);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lastRebasedTime = lastRebasedTime.add(times.mul(15 minutes));
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            _swapBack();
        }

        if (manualSwapEnabled == true) {
            _sendFeesToOperationWallet();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        if (shouldRebase()) {
            _rebase();
        }

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _swapBack() private swapping() {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

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

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHRiskFreeValue = amountETH.mul(riskFreeValue).div(
            totalETHFee
        );
        uint256 amountETHTreasury = amountETH.mul(treasury).div(totalETHFee);

        (bool success, ) = payable(treasuryAddress).call{
            value: amountETHTreasury,
            gas: 30000
        }("");
        (success, ) = payable(riskFreeValueAddress).call{
            value: amountETHRiskFreeValue,
            gas: 30000
        }("");

        success = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityAddress,
                block.timestamp
            );
        }
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = totalFee;

        if (recipient == liquidityProviderAddress) {
            _totalFee = _totalFee.add(sellFee);

            if (
                _feeDiscount[sender] > 0 &&
                block.timestamp < _discountEnds[sender]
            ) {
                _totalFee = _totalFee.sub(_feeDiscount[sender]);
            }
        }

        // bail early if there is no fee
        if (_totalFee < 1) {
            return 0;
        }

        uint256 feeAmount = gonAmount.mul(_totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;
    }

    function setFeeExempt(address _addr, bool value) external onlyOwner {
        _isFeeExempt[_addr] = value;
    }

    /**
     * @dev decrease the rebase rate, be very careful to not mistake the rebase rate
     * the initial rebaseRate is 2229, which is equivalent of 0.02229% per rebase
     */
    function decreaseRebaseRate(uint256 _rebaseRate) external onlyOwner {
        require(
            _rebaseRate < rebaseRate,
            "You can only decrease the rebase rate"
        );
        rebaseRate = _rebaseRate;
        emit DecreaseRebaseRate(_rebaseRate);
    }

    function addDiscounter(address discounter) external onlyOwner {
        require(discounter != address(0x0), "Zero address for discounter");
        _addDiscounter(discounter);
    }

    function removeDiscounter(address discounter) external onlyOwner {
        require(discounter != address(0x0), "Zero address for discounter");
        _removeDiscounter(discounter);
    }

    /**
     * @dev The Discounter contract will be able to give a discount
     * from 0 - 100 (in percentage). The endPeriod is the timestamp that
     * this discount will stop working.
     */
    function setDiscount(
        address who,
        uint256 amount,
        uint256 endPeriod
    ) external onlyDiscounter {
        require(amount < 101, "Cannot give discount of more than 100%");
        _feeDiscount[who] = amount;
        _discountEnds[who] = endPeriod;
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            return false;
        } else {
            return (liquidityProviderAddress == from ||
                liquidityProviderAddress == to);
        }
    }

    function shouldRebase() internal view returns (bool) {
        return
            initialDistributionFinished &&
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != address(pairContract) &&
            !inSwap &&
            block.timestamp >= (lastRebasedTime + 15 minutes);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !manualSwapEnabled &&
            !swapBackPaused &&
            msg.sender != address(pairContract) &&
            !inSwap &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }


    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSync() external {
        ILiquidityProvider(liquidityProviderAddress).sync();
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[liquidityProviderAddress].div(
            _gonsPerFragment
        );
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    receive() external payable {}

    /**
     * @dev START TRADING!!!
     */
    function startTrading(uint256 _lastRebaseTimestamp) external onlyOwner returns (bool) {
        require(
            initialDistributionFinished == false,
            "Trading already started"
        );
        initialDistributionFinished = true;
        _autoRebase = true;
        lastRebasedTime = _lastRebaseTimestamp; // last timestamp rebase from v1
        startedTrading = block.timestamp;

        return true;
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy)
        external
        onlyOwner
    {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _treasury,
        uint256 _riskFreeValue,
        uint256 _sellFee,
        uint256 _totalFee
    ) external onlyOwner {
        require(_totalFee <= 8, "buy fee can't be higher than 15%");
        require(_sellFee <= 10, "sellFee can't be higher than 20%");

        liquidityFee = _liquidityFee;
        treasury = _treasury;
        riskFreeValue = _riskFreeValue;
        sellFee = _sellFee;
        totalFee = _totalFee;

        emit LogFeesChanged(
            _liquidityFee,
            _treasury,
            _riskFreeValue,
            _sellFee,
            _totalFee
        );
    }

    function setGonSwapThreshold(uint256 _num, uint256 _denom)
        external
        onlyOwner
    {
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);

        emit LogGonSwapThresholdChanged(gonSwapThreshold);
    }

    function pauseSwapBack() external onlyOwner {
        require(!swapBackPaused, "Already paused.");
        swapBackPaused = true;

        emit LogSwapBackPaused(true);
    }

    function resumeSwapBack() external onlyOwner {
        require(swapBackPaused, "Already resumed.");
        swapBackPaused = false;

        emit LogSwapBackPaused(false);
    }

    function setRouterAddress(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0x0), "Zero Address");

        routerContractAddress = _routerAddress;
        router = IDEXRouter(routerContractAddress);

        liquidityProviderAddress = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        pairContract = ILiquidityProvider(liquidityProviderAddress);

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[address(this)][liquidityProviderAddress] = uint256(
            -1
        );

        emit RouterAddressChanged(_routerAddress);
    }

    function setOperationsAddress(address _operationsAddress)
        external
        onlyOwner
    {
        require(_operationsAddress != address(0x0), "Zero Address");

        operationsAddress = _operationsAddress;
    }

    function _sendFeesToOperationWallet() private swapping() {
        if (block.timestamp >= (_lastManualSwapTime + 4 hours)) {
            uint256 contractTokenBalance = _gonBalances[address(this)].div(
                _gonsPerFragment
            );

            _lastManualSwapTime = block.timestamp;
            _transferFrom(address(this), operationsAddress, contractTokenBalance);

            emit Transfer(address(this), operationsAddress, contractTokenBalance);
        }
    }

    function pauseTrading() external onlyOwner {
        initialDistributionFinished = false;
    }

    function resumeTrading() external onlyOwner {
        initialDistributionFinished = true;
    }

    function pauseRebases() external onlyOwner {
        require(_autoRebase == true, "Already paused!");
        _autoRebase = false;
    }

    function resumeRebases() external onlyOwner {
        require(_autoRebase == false, "Already resumed!");
        _autoRebase = true;
    }

    function setManualSwap() external onlyOwner {
        require(manualSwapEnabled == false, "Manual swap back already enabled.");
        manualSwapEnabled = true;
        _lastManualSwapTime = block.timestamp;
    }

    function pauseManualSwap() external onlyOwner {
        require(manualSwapEnabled == true, "Manual swap back already paused.");
        manualSwapEnabled = false;
    }
}