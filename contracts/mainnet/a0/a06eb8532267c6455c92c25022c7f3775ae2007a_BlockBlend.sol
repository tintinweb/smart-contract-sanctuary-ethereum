/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
/**
    ██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗██████╗░██╗░░░░░███████╗███╗░░██╗██████╗░
    ██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║░░░░░██╔════╝████╗░██║██╔══██╗
    ██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░██████╦╝██║░░░░░█████╗░░██╔██╗██║██║░░██║
    ██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░██╔══██╗██║░░░░░██╔══╝░░██║╚████║██║░░██║
    ██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗██████╦╝███████╗███████╗██║░╚███║██████╔╝
    ╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚══════╝╚═╝░░╚══╝╚═════╝░
    Telegram - https://t.me/blockblendIO
    Audited
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: ethtoken.sol

pragma solidity ^0.8.7;



/**
 * @dev Interfaces
 */

interface IDEXFactory {
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

interface IDEXRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
}

contract BlockBlend is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _totalSupply;
    uint256 _maxSupply = 100_000_000 * (10 ** decimals());
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // fees & addresses
    mapping (string => uint) txFees;
    
    mapping (address => bool) public feeExempt;
    mapping (address => bool) public txLimitExempt;
    
    address public farmingAddress = 0xA56CC65a2aa9B7cC3A2a1819D14B67532Cf031dc;
    address public taxAddress = 0xA56CC65a2aa9B7cC3A2a1819D14B67532Cf031dc;

    // taxes for differnet levels
    struct TaxLevels {
        uint taxDiscount;
        uint amount;
    }

    struct TokenFee {
        uint forMarketing;
        uint forLiquidity;
        uint forDev;
        uint forFarming;
    }

    struct TxLimit {
        uint buyLimit;
        uint sellLimit;
        uint cooldown;
        mapping(address => uint) buys;
        mapping(address => uint) sells;
        mapping(address => uint) lastTx;
    }

    mapping (uint => TaxLevels) taxTiers;
    TxLimit txLimits;

    IDEXRouter public router;
    address public pair;
    address bridge;

    constructor(address _bridge) {
        _name = "BlockBlend";
        _symbol = "BBL";
        _decimals = 18;
        bridge = _bridge;
        
        /**
            Disable fees & limits for:
            - deployer
            - farming
            - tax collector
        */
        feeExempt[msg.sender] = true;
        txLimitExempt[msg.sender] = true;
        feeExempt[farmingAddress] = true;
        txLimitExempt[farmingAddress] = true;
        feeExempt[taxAddress] = true;
        txLimitExempt[taxAddress] = true;

        /**
            Set default buy/sell tx fees (no tax on transfers)
            - marketing, dev, liqudity, farming
        */
        txFees["marketingBuy"] = 2;
        txFees["devBuy"] = 1;
        txFees["liquidityBuy"] = 1;
        txFees["farmingBuy"] = 1;

        txFees["marketingSell"] = 3;
        txFees["devSell"] = 2;
        txFees["liquiditySell"] = 2;
        txFees["farmingSell"] = 2;

        /**
            Set default tx limits
            - Cooldown, buy limit, sell limit
        */
        txLimits.cooldown = 3 minutes;
        txLimits.buyLimit = 200_000 ether;
        txLimits.sellLimit = 50_000 ether; // 0.25%
        
        /**
            Set default tax levels.
            - 150k+ tokens: 15% discount on fees
            - 1m+ tokens: 35% discount on fees
        */
        taxTiers[0].taxDiscount = 50;
        taxTiers[0].amount = 500_000 ether;
        taxTiers[1].taxDiscount = 100;
        taxTiers[1].amount = 1_000_000 ether;

        address WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH Mainnet
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        approve(_router, _totalSupply);
    }

    /**
        Sets buy/sell transaction fees
    */
    event Fees(
        uint _marketingBuy,
        uint _devBuy,
        uint _liquidityBuy,
        uint _farmingBuy,
        uint _marketingSell,
        uint _devSell,
        uint _liquiditySell,
        uint _farmingSell
    );

    function setFees(
        uint _marketingBuy,
        uint _devBuy,
        uint _liquidityBuy,
        uint _farmingBuy,
        uint _marketingSell,
        uint _devSell,
        uint _liquiditySell,
        uint _farmingSell
    ) external onlyOwner {
        require(_marketingBuy <= 8, "Marketing fee is too high!");
        require(_devBuy <= 8, "Dev fee is too high!");
        require(_liquidityBuy <= 8, "Liquidity fee is too high!");
        require(_farmingBuy <= 8, "Farming fee is too high!");
        require(_marketingSell <= 8, "Marketing fee is too high!");
        require(_devSell <= 8, "Dev fee is too high!");
        require(_liquiditySell <= 8, "Liquidity fee is too high!");
        require(_farmingSell <= 8, "Farming fee is too high!");

        txFees["marketingBuy"] = _marketingBuy;
        txFees["devBuy"] = _devBuy;
        txFees["liquidityBuy"] = _liquidityBuy;
        txFees["farmingBuy"] = _farmingBuy;

        txFees["marketingSell"] = _marketingSell;
        txFees["devSell"] = _devSell;
        txFees["liquiditySell"] = _liquiditySell;
        txFees["farmingSell"] = _farmingSell;

        emit Fees(
            _marketingBuy,
            _devBuy,
            _liquidityBuy,
            _farmingBuy,
            _marketingSell,
            _devSell,
            _liquiditySell,
            _farmingSell
        );
    }

    /**
        Returns buy/sell transaction fees
    */
    function getFees() public view returns(
        uint marketingBuy,
        uint devBuy,
        uint liquidityBuy,
        uint farmingBuy,
        uint marketingSell,
        uint devSell,
        uint liquiditySell,
        uint farmingSell
    ) {
        return (
            txFees["marketingBuy"],
            txFees["devBuy"],
            txFees["liquidityBuy"],
            txFees["farmingBuy"],
            txFees["marketingSell"],
            txFees["devSell"],
            txFees["liquiditySell"],
            txFees["farmingSell"]
        );
    }

    /**
        Sets the tax collector contracts
    */
    function setTaxAddress(address _farmingAddress, address _taxAddress) external onlyOwner {
        farmingAddress = _farmingAddress;
        taxAddress = _taxAddress;
    }

    /**
        Sets the tax free trading for the specific address
    */
    function setFeeExempt(address _address, bool _value) external onlyOwner {
        feeExempt[_address] = _value;
    }

    /**
        Sets the limit free trading for the specific address
    */
    function setTxLimitExempt(address _address, bool _value) external onlyOwner {
        txLimitExempt[_address] = _value;
    }

    /**
        Sets the different tax levels for buy transactions
    */
    function setTaxTiers(uint _discount1, uint _amount1, uint _discount2, uint _amount2) external onlyOwner {
        require(_discount1 > 0 && _discount2 > 0 && _amount1 > 0 && _amount2 > 0, "Values have to be bigger than zero!");
        taxTiers[0].taxDiscount = _discount1;
        taxTiers[0].amount = _amount1;
        taxTiers[1].taxDiscount = _discount2;
        taxTiers[1].amount = _amount2;
    }

    /**
        Returns the different tax levels for buy transactions
    */
    function getTaxTiers() public view returns(uint discount1, uint amount1, uint discount2, uint amount2) {
        return (taxTiers[0].taxDiscount, taxTiers[0].amount, taxTiers[1].taxDiscount, taxTiers[1].amount);
    }

    /**
        Sets the sell/buy limits & cooldown period
    */
    function setTxLimits(uint _buyLimit, uint _sellLimit, uint _cooldown) external onlyOwner {
        require(_buyLimit >= _totalSupply.div(200), "Buy transaction limit is too low!"); // 0.5%
        require(_sellLimit >= _totalSupply.div(400), "Sell transaction limit is too low!"); // 0.25%
        require(_cooldown <= 30 minutes, "Cooldown should be 30 minutes or less!");

        txLimits.buyLimit = _buyLimit;
        txLimits.sellLimit = _sellLimit;
        txLimits.cooldown = _cooldown;
    }

    /**
        Returns the sell/buy limits & cooldown period
    */
    function getTxLimits() public view returns(uint buyLimit, uint sellLimit, uint cooldown) {
        return (txLimits.buyLimit, txLimits.sellLimit, txLimits.cooldown);
    }

    /**
        Checks the BUY transaction limits for the specific user with the sent amount
    */
    function checkBuyTxLimit(address _sender, uint256 _amount) internal view {
        require(
            txLimitExempt[_sender] == true ||
            txLimits.buys[_sender].add(_amount) < txLimits.buyLimit,
            "Buy transaction limit reached!"
        );
    }

    /**
        Checks the SELL transaction limits for the specific user with the sent amount
    */
    function checkSellTxLimit(address _sender, uint256 _amount) internal view {
        require(
            txLimitExempt[_sender] == true ||
            txLimits.sells[_sender].add(_amount) < txLimits.sellLimit,
            "Sell transaction limit reached!"
        );
    }
    
    /**
        Saves the recent buy/sell transactions
        The function used by _transfer() when the cooldown/tx limit is active
    */
    function setRecentTx(bool _isSell, address _sender, uint _amount) internal {
        if(txLimits.lastTx[_sender].add(txLimits.cooldown) < block.timestamp) {
            _isSell ? txLimits.sells[_sender] = _amount : txLimits.buys[_sender] = _amount;
        } else {
            _isSell ? txLimits.sells[_sender] += _amount : txLimits.buys[_sender] += _amount;
        }

        txLimits.lastTx[_sender] = block.timestamp;
    }

    /**
        Returns the recent buys, sells and the last transaction for the specific wallet
    */
    function getRecentTx(address _address) public view returns(uint buys, uint sells, uint lastTx) {
        return (txLimits.buys[_address], txLimits.sells[_address], txLimits.lastTx[_address]);
    }

    /**
        Returns the token price
    */
    function getTokenPrice(uint _amount) public view returns(uint) {
        IPancakeswapV2Pair pcsPair = IPancakeswapV2Pair(pair);
        IERC20 token1 = IERC20(pcsPair.token1());
    
    
        (uint Res0, uint Res1,) = pcsPair.getReserves();

        // decimals
        uint res0 = Res0*(10**token1.decimals());
        //uint256 res0 = Res0*(10**decimals());
        return((_amount.mul(res0)).div(Res1)); // returns how much kaiken you will get on that eth amount
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint marketingFee;
        uint devFee;
        uint liquidityFee;
        uint farmingFee;

        uint taxDiscount;
        bool hasFees = true;

        // BUY
        if(from == pair) {
            checkBuyTxLimit(to, amount); // todo test

            setRecentTx(false, to, amount);

            marketingFee = txFees["marketingBuy"];
            devFee = txFees["devBuy"];
            liquidityFee = txFees["liquidityBuy"];
            farmingFee = txFees["farmingBuy"];

            // Tax levels for bigger buys
            if(amount >= taxTiers[0].amount && amount < taxTiers[1].amount) {
                taxDiscount = taxTiers[0].taxDiscount;
            } else if(amount >= taxTiers[1].amount) {
                taxDiscount = taxTiers[1].taxDiscount;
            }
        }
        // SELL
        else if(to == pair) {
            checkSellTxLimit(from, amount);

            setRecentTx(true, from, amount);

            marketingFee = txFees["marketingSell"];
            devFee = txFees["devSell"];
            liquidityFee = txFees["liquiditySell"];
            farmingFee = txFees["farmingSell"];
        }

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if(feeExempt[to] || feeExempt[from]) {
            hasFees = false;
        }

        if(hasFees && (to == pair || from == pair)) {
            TokenFee memory TokenFees;
            TokenFees.forMarketing = amount.mul(marketingFee).mul(100 - taxDiscount).div(10000);
            TokenFees.forLiquidity = amount.mul(liquidityFee).mul(100 - taxDiscount).div(10000);
            TokenFees.forDev = amount.mul(devFee).mul(100 - taxDiscount).div(10000);
            TokenFees.forFarming = amount.mul(farmingFee).mul(100 - taxDiscount).div(10000);

            uint totalFees =
                TokenFees.forMarketing
                .add(TokenFees.forLiquidity)
                .add(TokenFees.forDev)
                .add(TokenFees.forFarming);

            amount = amount.sub(totalFees);

            //_balances[farmingAddress] += TokenFees.forFarming; // farming pool
            //emit Transfer(from, farmingAddress, TokenFees.forFarming);

            _balances[taxAddress] += totalFees; // dev, lp, marketing fees (+ farming to save gas)
            emit Transfer(from, taxAddress, totalFees);
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_maxSupply <= _totalSupply + amount, "Mint error! Amount can't be more than the total supply on BSC!");

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }

    function mint(address recipient, uint256 amount) public virtual onlyBridge {
        _mint(recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public virtual onlyBridge {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    modifier onlyBridge {
      require(msg.sender == bridge, "only bridge has access to this child token function");
      _;
    }
}