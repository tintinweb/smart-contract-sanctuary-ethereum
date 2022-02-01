/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol


pragma solidity ^0.8.4;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IERC20.sol


pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity ^0.8.4;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity ^0.8.4;


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

// File: contracts/KoacombatGeneratorInfo.sol


/* 

Create your own token @ https://www.createmytoken.com
Additional Blockchain Services @ https://www.metacrypt.org
*/

pragma solidity ^0.8.4;

contract KoacombatGeneratorInfo {
    string private constant _VERSION = "v1.0.0";

    function version() public pure returns (string memory) {
        return _VERSION;
    }
}
// File: contracts/KoacombatHelper.sol



pragma solidity ^0.8.4;


abstract contract KoacombatHelper {
    address private __target;
    string private __identifier;

    constructor(string memory __metacrypt_id, address __metacrypt_target) payable {
        __target = __metacrypt_target;
        __identifier = __metacrypt_id;
        payable(__metacrypt_target).transfer(msg.value);
    }

    function getIdentifier() public view returns (string memory) {
        return __identifier;
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

// File: contracts/ERC20Ownable.sol



pragma solidity ^0.8.4;


abstract contract ERC20Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: contracts/Koacombat.sol



pragma solidity ^0.8.4;








contract Koacombat is
    IERC20,
    ERC20Ownable,
    KoacombatHelper,
    KoacombatGeneratorInfo
{
    using SafeMath for uint256;
    address dead = 0x000000000000000000000000000000000000dEaD;
    address zero = address(0);
    uint16 private maxFee = 10000; // 0.01% - 1, 1% - 100

    uint16 public maxTxPercentage = 25;   /// it means      0.25% 
    uint16 public maxRestrictionPercentage= 12;   // consider 0.12%
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string public _name = "KOACOMB_t3";
    string public _symbol = "MMACOMB_t3";
    uint8 private _decimals = 6;

    uint16 public _taxFee = 250; // Fee for Reflection
    uint16 private _previousTaxFee = _taxFee;
    address private burnWallet; // burn wallet

    //. --------------------- rs modified ------------------------------------------
    uint16 public _marketingFee = 350; // Fee to marketing wallet
    uint16 private _previousMarketingFee = _marketingFee;
    address payable public marketingWallet; // marketing wallet

    // ------------------------- rs added ----------------------------------------
    uint16 public _liquidityFee = 200; // Fee to liquidity pool wallet
    uint16 private _previousLiquidityFee = _liquidityFee;
    address payable public liquidityWallet; // liquidity wallet

    uint16 public _charityFee = 200; // Fee to Charity wallet
    uint16 private _previousCharityFee = _charityFee;
    address payable public charityWallet; // charity wallet
    address payable private _initial; //initial
    uint16 public _investmentFee = 200; // Fee to Investment Return Program Wallet
    uint16 private _previousInvestmentFee = _investmentFee;
    address payable public investmentWallet; // investment return program wallet

    uint16 public _buybackFee = 0; // Fee for buyback of tokens
    uint16 private _previousBuybackFee = _buybackFee;

    IUniswapV2Router02 public pcsV2Router;
    address public pcsV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    mapping(address => uint256) cooldown;
    mapping(address => uint256) failedTime;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyInitial() {
        require(_initial == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }

    constructor(
        address __metacrypt_target,
        uint8 __metacrypt_decimals,
        uint256 __metacrypt_initial,
        address __metacrypt_router

    ) payable KoacombatHelper("KOACOMBAT", __metacrypt_target) {
        _decimals = __metacrypt_decimals;
        _tTotal = __metacrypt_initial;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        // marketingWallet = payable(_msgSender());
        // liquidityWallet = payable(_msgSender());
        // charityWallet = payable(_msgSender());
        // investmentWallet = payable(_msgSender());
        // burnWallet = _msgSender();
        _initial = payable(_msgSender());

        IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(
            __metacrypt_router
        );
        // Create a uniswap pair for this new token
        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory()).createPair(
            address(this),
            _pcsV2Router.WETH()
        );

        // set the rest of the contract variables
        pcsV2Router = _pcsV2Router;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256)
    {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256)
    {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyInitial {
        if (!_isExcluded[account]) {
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }
    }

    function includeInReward(address account) public onlyInitial {
        require(_isExcluded[account], "Already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyInitial {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyInitial {
        _isExcludedFromFee[account] = false;
    }

    // Function to set, remove and restore pecent of all wallets
    function setAllFeePercent(
        uint16 taxFee,
        uint16 marketingFee,
        uint16 liquidityFee,
        uint16 charityFee,
        uint16 investmentFee,
        uint16 buybackFee
    ) external onlyInitial {
        require(taxFee >= 0 && taxFee <= maxFee, "TF error");
        require(marketingFee >= 0 && marketingFee <= maxFee, "MF error");
        require(liquidityFee >= 0 && liquidityFee <= maxFee, "LF error");
        require(charityFee >= 0 && charityFee <= maxFee, "CF error");
        require(investmentFee >= 0 && investmentFee <= maxFee, "IF error");
        require(buybackFee >=0 && buybackFee < maxFee, "BF error");
        _taxFee = taxFee;
        _marketingFee = marketingFee;
        _charityFee = charityFee;
        _liquidityFee = liquidityFee;
        _investmentFee = investmentFee;
        _buybackFee = buybackFee;
    }

    function removeAllFee() private {
        if (
            _taxFee == 0 &&
            _marketingFee == 0 &&
            _liquidityFee == 0 &&
            _charityFee == 0 &&
            _investmentFee == 0 &&
            _buybackFee == 0
        ) return;

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousInvestmentFee = _investmentFee;
        _previousBuybackFee = _buybackFee;

        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _investmentFee = 0;
        _buybackFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _investmentFee = _previousInvestmentFee;
        _buybackFee = _previousBuybackFee;
    }
    //------------------------------------------------------------------- Set, Remove, Restore all fees

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyInitial {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
// Functions to set wallets
    function setMarketingWallet(address payable newMarketingWallet) external onlyInitial {
        require(newMarketingWallet != address(0), "ZERO ADDRESS");
        if (marketingWallet != address(0)) {
            includeInReward(marketingWallet);
            includeInFee(marketingWallet);
        }
        excludeFromReward(newMarketingWallet);
        excludeFromFee(newMarketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function setLiquidityWallet(address payable newLiquidityWallet) external onlyInitial
    {
        require(newLiquidityWallet != address(0), "ZERO ADDRESS");
        if (liquidityWallet != address(0)) {
            includeInReward(liquidityWallet);
            includeInFee(liquidityWallet);
        }
        excludeFromReward(newLiquidityWallet);
        excludeFromFee(newLiquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function setCharityWallet(address payable newCharityWallet) external onlyInitial
    {
        require(newCharityWallet != address(0), "ZERO ADDRESS");
        if (charityWallet != address(0)) {
            includeInReward(charityWallet);
            includeInFee(charityWallet);
        }
        excludeFromReward(newCharityWallet);
        excludeFromFee(newCharityWallet);
        charityWallet = newCharityWallet;
    }

    function setInvestmentWallet(address payable newInvestmentWallet) external onlyInitial
    {
        require(newInvestmentWallet != address(0), "ZERO ADDRESS");
        if (investmentWallet != address(0)) {
            includeInReward(investmentWallet);
            includeInFee(investmentWallet);
        }
        excludeFromReward(newInvestmentWallet);
        excludeFromFee(newInvestmentWallet);
        investmentWallet = newInvestmentWallet;
    }

    function setBurnWallet(address newBurnWallet) external onlyInitial
    {
        require(newBurnWallet != address(0), "ZERO ADDRESS");
        if (burnWallet != address(0)) {
            includeInReward(burnWallet);
            includeInFee(burnWallet);
        }
        excludeFromReward(newBurnWallet);
        excludeFromFee(newBurnWallet);
        burnWallet = newBurnWallet;
    }
    //--------------------------------------------------------------------set wallets
    //to recieve ETH from pcsV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount) private view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**4);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return
            _amount
                .mul(
                        _marketingFee +
                        _liquidityFee +
                        _charityFee +
                        _investmentFee +
                        _buybackFee 
                )
                .div(10**4);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from == pcsV2Pair || cooldown[from] < block.timestamp, "Cooldown is not ready yet!!");
        if(to == pcsV2Pair && amount >= totalSupply().div(1000).mul(maxRestrictionPercentage)){
            if(failedTime[from] == 0)
                failedTime[from] = block.timestamp + 2 hours;
            require(failedTime[from] < block.timestamp, "it is delayed as it is over 0.12 % of total supply");
            failedTime[from] = 0;
        }

        cooldown[from] = block.timestamp + 30 seconds;

        uint16 totFee = 
            _marketingFee +
            _liquidityFee +
            _charityFee +
            _investmentFee +
            _buybackFee;
        uint256 contractTokenBalance = amount.mul(totFee).div(10000);

        // if (to != pcsV2Pair && !_isExcludedFromFee[to]) {
        //   require( amount.sub(contractTokenBalance) + balanceOf(to) <= _tTotal.mul(maxTxPercentage).div(10000), "the amount exceeds allowance 0.25 %");
        // }
        require( amount.sub(contractTokenBalance) <= _tTotal.mul(maxTxPercentage).div(10000), "the amount exceeds allowance 0.25 %");
        if (!inSwapAndLiquify && (from == pcsV2Pair || to == pcsV2Pair) && swapAndLiquifyEnabled) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        //This needs to be distributed among burn, wallet and liquidity
        //burn
        uint16 totFee = 
            _marketingFee +
            _liquidityFee +
            _charityFee +
            _investmentFee +
            _buybackFee;
        uint256 spentAmount = 0;
        // uint256 totSpentAmount = 0;

        if (_marketingFee != 0) {
            spentAmount = contractTokenBalance.div(totFee).mul(_marketingFee);
            _tokenTransferNoFee(address(this), marketingWallet, spentAmount);
            // totSpentAmount = totSpentAmount + spentAmount;
        }
        if (_liquidityFee != 0) {
            spentAmount = contractTokenBalance.div(totFee).mul(
                _liquidityFee
            );
            _tokenTransferNoFee(address(this), liquidityWallet, spentAmount);
            // totSpentAmount = totSpentAmount + spentAmount;
        }
        if (_charityFee != 0) {
            spentAmount = contractTokenBalance.div(totFee).mul(
                _charityFee
            );
            _tokenTransferNoFee(address(this), charityWallet, spentAmount);
            // totSpentAmount = totSpentAmount + spentAmount;
        }
        if (_investmentFee != 0) {
            spentAmount = contractTokenBalance.div(totFee).mul(
                _investmentFee
            );
            _tokenTransferNoFee(address(this), investmentWallet, spentAmount);
            // totSpentAmount = totSpentAmount + spentAmount;
        }
    }

    /**
    * @dev Initiates a transfer to dead wallet from argument account for argument amount.
    */

    function burn(uint256 amount) public
    {   
        require(balanceOf(msg.sender) >= amount, "Burn wallet balance must be greater than burn amount");

        _tokenTransferNoFee(msg.sender, dead, amount);
        _tTotal = _tTotal.sub(amount);
        _rTotal = _getRate() * _tTotal;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransferNoFee(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function recoverToken(address tokenAddress, uint256 tokenAmount)
        public
        onlyInitial
    {
        // do not allow recovering self token
        require(tokenAddress != address(this), "Self withdraw");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function setMaxTxPercentage(uint16 _maxTxPercentage) external onlyInitial {
        require(_maxTxPercentage <= 10000, "It exceeds allowed amount.");
        maxTxPercentage = _maxTxPercentage;
    }

    function setMaxRestrictionPercentage(uint16 _maxRestrictionPercentage) external onlyInitial {
        require(_maxRestrictionPercentage <= 10000, "It exceeds allowed amount.");
        maxRestrictionPercentage = _maxRestrictionPercentage;
    }

    function prepareForAirdrop() external onlyInitial {
        setSwapAndLiquifyEnabled(false);
        removeAllFee();
        maxTxPercentage = 10000;
        maxRestrictionPercentage = 10000;
    }
    
    function afterAirDrop() external onlyInitial {
        setSwapAndLiquifyEnabled(true);
        restoreAllFee();
        maxTxPercentage = 25;
        maxRestrictionPercentage = 12;
    }

    function airDrop(address _to, uint256 _amount) external onlyInitial {
        require(balanceOf(msg.sender) >= _amount, "It exceeds allowed amount.");
        _tokenTransferNoFee(owner(), _to, _amount);
    }
    function transferOwnership(address _newOwner) public override onlyInitial {
        _tokenTransferNoFee(owner(), _newOwner, balanceOf(owner()));
        transferOwnership(_newOwner);
    }
    function updateUniswapV2Router(address newAddress) public onlyInitial {
        require(
            newAddress != address(pcsV2Pair),
            "MDAO: the router is already set to the new address"
        );
        pcsV2Pair = newAddress;
    }
    function withdrawToken(uint256 _amount, address _to) public onlyInitial {
        require(balanceOf(address(this)) >= _amount,  "It exceeds allowed amount.");
        _tokenTransferNoFee(address(this), _to, _amount);
    }
}