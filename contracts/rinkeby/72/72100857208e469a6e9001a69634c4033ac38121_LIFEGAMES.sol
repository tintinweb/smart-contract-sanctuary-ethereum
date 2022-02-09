/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address lpPair);

    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

contract LIFEGAMES is IERC20 {
    using SafeMath for uint256;

    // reflection
    uint256 private _tTotal = 1 * 1e6 * 1e18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 10;
    uint256 private _previousTaxFee = _taxFee;
    uint16 public maxTransferAmountRate = 100;
    mapping(address => uint256) private _rOwned;
    address[] private _excluded;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => bool) private _isExcludedFromFee;
    // ---------------------------------------------------

    bool private autoAddLiquidity = false;
    uint256 public autoAddLiquidityThreshold = 0;

    event Burn(
        address indexed sender,
        uint256 amount
    );

    mapping(address => bool) public bridges;

    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping(address => uint256) _tOwned;
    mapping(address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) _isFeeExcluded;
    mapping(address => bool) private _isSniper;

    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private _excludedFromAntiWhale;

    string constant private _name = "LIFEGAMES";
    string constant private _symbol = "LFG";
    uint8 private _decimals = 18;

    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private sameBlockActive = true;
    bool private sniperProtection = true;
    uint256 private _liqAddBlock = 0;

    struct Fees {
        uint16 distributionToHoldersFee;
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct StaticValuesStruct {
        uint16 maxTotalFee;
        uint16 distributionToHoldersFee;
        uint16 maxBuyTaxes;
        uint16 maxSellTaxes;
        uint16 maxTransferTaxes;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 buyBackAndBurn;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        distributionToHoldersFee : 1500,
        buyFee : 1000,
        sellFee : 1000,
        transferFee : 0
    });

    Ratios public _ratios = Ratios({
        liquidity : 300,
        buyBackAndBurn : 300,
        total: 600
    });

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxTotalFee: 300,
        distributionToHoldersFee: 300,
        maxBuyTaxes : 300,
        maxSellTaxes : 300,
        maxTransferTaxes : 300,
        masterTaxDivisor : 10000
    });

    IUniswapV2Router02 public dexRouter;
    address public lpPair;
    //address public currentRouter;

    //address private WETH;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private zero = 0x0000000000000000000000000000000000000000;

    address payable public liquidityAddress;
    // si la cartera de buybackandburn y la de liquidez son la misma eliminamos esta declaración y su update (línea 1147)
    address payable public buybackAndBurnAddress;

    bool public contractSwapEnabled = false;
    uint256 private swapThreshold = _tTotal / 20000;
    uint256 private swapAmount = _tTotal * 5 / 1000;
    bool inSwap;

    bool public tradingActive = false;
    bool public hasLiqBeenAdded = false;

    address public busdAddress;

    uint256 whaleFeePercent = 0;
    uint256 whaleFee = 0;
    bool public transferToPoolsOnSwaps = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBridge() {
        require(bridges[msg.sender] == true, "Only bridges contracts can call this function");
        _;
    }
    modifier antiWhale(address sender,address recipient,uint256 amount) {
		if (maxTransferAmount() > 0) {
			if (_excludedFromAntiWhale[sender] == false && _excludedFromAntiWhale[recipient] == false) {
				require(amount <= maxTransferAmount(), "ONYX::antiWhale: Transfer amount exceeds the maxTransferAmount");
			}
		}
		_;
	}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountAVAX, uint256 amount);
    event SniperCaught(address sniperAddress);

    constructor (address[] memory addresses) {

        // _tOwned[msgSender] = _tTotal  / 100 * 100;
        // _tOwned[address(this)] = 0;

        //_rOwned[msgSender] = _rTotal / 100 * 100; // 100%
        //_rOwned[_msgSender()] = _rTotal;
        _excludedFromAntiWhale[msg.sender] = true;
		_excludedFromAntiWhale[address(0)] = true;
		_excludedFromAntiWhale[address(this)] = true;
        _rOwned[address(this)] = 0;
        _tOwned[address(this)] = 0;

        //_tOwned[msg.sender] = _rTotal;
        _rOwned[msg.sender] = _rTotal;
        _owner = msg.sender;

        busdAddress = address(addresses[0]);

        _isFeeExcluded[_owner] = true;
        _isFeeExcluded[address(this)] = true;
        _isFeeExcluded[busdAddress] = true;

        _approve(msg.sender, addresses[1], type(uint256).max);
        _approve(address(this), addresses[1], type(uint256).max);
        _approve(msg.sender, busdAddress, type(uint256).max);
        _approve(address(this), busdAddress, type(uint256).max);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addresses[1]);
        //lpPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), busdAddress);
        
        //lpPairs[lpPair] = true;
        dexRouter = _uniswapV2Router;
        bridges[addresses[2]] = true;
        setLiquidityAddress(addresses[3]);
        setBuybackAndBurnAddress(addresses[4]);

        emit Transfer(zero, msg.sender, _tTotal);
        emit OwnershipTransferred(address(0), msg.sender);

    }

    //===============================================================================================================
    //===============================================================================================================
    //===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        _isFeeExcluded[_owner] = false;
        _isFeeExcluded[newOwner] = true;

        if (_tOwned[_owner] > 0) {
            _transfer(_owner, newOwner, _tOwned[_owner]);
        }

        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _isFeeExcluded[_owner] = false;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
    //===============================================================================================================
    //===============================================================================================================
    //===============================================================================================================

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {return _tTotal;}

    function decimals() external view override returns (uint8) {return _decimals;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function name() external pure override returns (string memory) {return _name;}

    function getOwner() external view override returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) {
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }
        function maxTransferAmount() public view returns (uint256) {
		return _tTotal.mul(maxTransferAmountRate).div(10000);
	}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function setStartingProtections(uint8 _block) external onlyOwner {
        require(snipeBlockAmt == 0 && _block <= 5 && !hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        sameBlockActive = antiBlock;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function isFeeExcluded(address account) public view returns (bool) {
        return _isFeeExcluded[account];
    }

    function enableTrading() public onlyOwner {
        require(!tradingActive, "Trading already enabled!");
        require(hasLiqBeenAdded, "Liquidity must be added.");
        _liqAddBlock = block.number;
        tradingActive = true;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function setTaxes(uint16 distributionToHoldersFee, uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(
            distributionToHoldersFee <= staticVals.distributionToHoldersFee &&
            buyFee <= staticVals.maxBuyTaxes &&
            sellFee <= staticVals.maxSellTaxes &&
            transferFee <= staticVals.maxTransferTaxes, "MAX TOTAL BUY FEES EXCEEDED 3%");

        require((distributionToHoldersFee + buyFee + transferFee) <= staticVals.maxTotalFee, "MAX TOTAL BUY FEES EXCEEDED 3%");
        require((distributionToHoldersFee + sellFee + transferFee) <= staticVals.maxTotalFee,  "MAX TOTAL SELL FEES EXCEEDED 3%");

        _taxRates.distributionToHoldersFee = distributionToHoldersFee;
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 liquidity, uint16 buyBackAndBurn) external onlyOwner {
        _ratios.liquidity = liquidity;
        _ratios.buyBackAndBurn = buyBackAndBurn;
        _ratios.total = liquidity + buyBackAndBurn;
    }

    function setLiquidityAddress(address _liquidityAddress) public onlyOwner {
        require(
            _liquidityAddress != address(0),
            "_liquidityAddress address cannot be 0"
        );
        liquidityAddress = payable(_liquidityAddress);
    }

    function setBuybackAndBurnAddress(address _buybackAndBurnAddress)
    public
    onlyOwner
    {
        require(
            _buybackAndBurnAddress != address(0),
            "_buybackAndBurnAddress address cannot be 0"
        );
        buybackAndBurnAddress = payable(_buybackAndBurnAddress);
    }

    function setContractSwapSettings(bool _enabled) external onlyOwner {
        contractSwapEnabled = _enabled;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function setNewRouter(address newRouter, address busd) public onlyOwner() {
        require(!hasLiqBeenAdded);
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(busd), address(this));
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(busd), address(this));
        }
        else {
            lpPair = get_pair;
        }
        lpPairs[lpPair] = true;
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled = false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
        && to != owner()
        && tx.origin != owner()
        && !_liquidityHolders[to]
        && !_liquidityHolders[from]
        && to != DEAD
        && to != address(0)
        && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual antiWhale(from, to, amount) returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_hasLimits(from, to)) {
            if (!tradingActive) {
                revert("Trading not yet enabled!");
            }
        }

        bool takeFee = true;

        if (_isFeeExcluded[from] || _isFeeExcluded[to]) {
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        if (sniperProtection) {
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            if (!hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0
                && lpPairs[from]
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        //_tOwned[from] -= amount;

        if (inSwap) {
             return _basicTransfer(from, to, amount);
        }

        uint256 contractTokenBalance = _tOwned[address(this)];
        if (contractTokenBalance >= swapAmount) {
            contractTokenBalance = swapAmount;
        }

        if (!inSwap
        && !lpPairs[from]
        && contractSwapEnabled
        && contractTokenBalance >= swapThreshold
        ) {
            contractSwap(contractTokenBalance);
        }

        //uint256 amountReceived = amount;

        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount = amount;
        uint256 tFee;

        if (takeFee) {

            // apply buy, sell or transfer fees

            //amountReceived = takeTaxes(from, to, amount);
            // take taxes
            uint256 totalFee = 0;
            uint256 antiWhaleAmount = 0;

            // BUY
            if (from == lpPair) {
                // BUY FEE
                totalFee += _taxRates.buyFee;

                // DISTRIBUTE HOLDERS FEES
                if (_taxRates.distributionToHoldersFee > 0) {
                    totalFee += _taxRates.distributionToHoldersFee;
                }
            }

            // SELL
            else if (to == lpPair) {
                // SELL FEE
                if (_taxRates.sellFee > 0){
                    totalFee += _taxRates.sellFee;
                }

                // DISTRIBUTE HOLDERS FEES
                if (_taxRates.distributionToHoldersFee > 0) {
                    totalFee += _taxRates.distributionToHoldersFee;
                }

                // ANTIWHALE
                if (whaleFee > 0) {
                    antiWhaleAmount = calculateWhaleFee(amount);
                    totalFee += antiWhaleAmount;
                }
            } 
            
            // TRANSFER
            else {
                if (_taxRates.transferFee > 0) {
                    totalFee += _taxRates.transferFee;
                }
            }
            
            /*
            // Ditribution to holders
            if (_taxRates.distributionToHoldersFee > 0) {
                totalFee += _taxRates.distributionToHoldersFee;
            }
            */

            // CALC FEES AMOUT AND SEND TO CONTRACT
            if (totalFee > 0) {
                uint256 feeAmount = amount * totalFee / staticVals.masterTaxDivisor;
                _tOwned[address(this)] += feeAmount;
                emit Transfer(from, address(this), feeAmount);
                //amountReceived =  amount - feeAmount;
                tTransferAmount =  amount - feeAmount;
                rAmount = tTransferAmount;
            }
        }

        //_tOwned[from] -= amount;

        if (staticVals.distributionToHoldersFee > 0) {
             // standart transfer
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount, tFee) = _getValues(amount);
            _rOwned[from] = _rOwned[from].sub(rAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);
            //_tOwned[to] = _tOwned[to].add(rTransferAmount); // maybe not needed
            //_takeDistributionHoldersFee(tDistributionHoldersFee);
            _reflectFee(rFee, tFee);
            //emit Transfer(from, to, tTransferAmount);
        }

        //_tOwned[to] += amountReceived;

        //return _tokenTransfer(from, to, amount, takeFee);

        //emit Transfer(from, to, amount);
        emit Transfer(from, to, tTransferAmount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // todo max whale fees
    function setWhaleFeesPercentage(uint256 _whaleFeePercent) external onlyOwner {
        whaleFeePercent = _whaleFeePercent;
    }

    // todo max whale fees
    function setWhaleFees(uint256 _whaleFee) external onlyOwner {
        whaleFee = _whaleFee;
    }

    // 0 -> Token -> 1000000
    // 1 -> BUSD  -> 1000

    function calculateWhaleFee(uint256 amount) public view returns (uint256) {
        uint256 busdAmount  = getOutEstimatedTokensForTokens(address(this), busdAddress, amount);
        uint256 liquidityAmount  = getOutEstimatedTokensForTokens(address(this), busdAddress, getReserves()[0]);

        // if amount in busd exceeded the % setted as whale, calc the estimated fee
        if (busdAmount >= ((liquidityAmount * whaleFeePercent) / staticVals.masterTaxDivisor)) {
            // mod of busd amount sold and whale amount
            uint256 modAmount = busdAmount % ((liquidityAmount * whaleFeePercent) / staticVals.masterTaxDivisor);
            return whaleFee * modAmount;
        } else {
            return 0;
        }
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 totalFee;
        uint256 antiWhaleAmount = 0;
        if (from == lpPair) {
            // BUY
            totalFee = _taxRates.buyFee;
            //totalFee = _taxRates.buyFee + _taxRates.distributionToHoldersFee;
        } else if (to == lpPair) {
            // SELL
            if (whaleFee > 0){
                antiWhaleAmount = calculateWhaleFee(amount);
            }
            totalFee = _taxRates.sellFee + antiWhaleAmount;
            //totalFee = _taxRates.sellFee + _taxRates.distributionToHoldersFee + antiWhaleAmount;
        } else {
            // TRANSFER
            totalFee = _taxRates.transferFee;
        }

      

        if (totalFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * totalFee / staticVals.masterTaxDivisor;
        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);
        return amount - feeAmount;
    }

    function contractSwap(uint256 numTokensToSwap) internal swapping {
        if (_ratios.total == 0) {
            return;
        }

        if (_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 amountToLiquidity = (numTokensToSwap * _ratios.liquidity) / (_ratios.total);
        uint256 amountToBuyBackAndBurn = (numTokensToSwap * _ratios.buyBackAndBurn) / (_ratios.total);

        uint256 estimatedBusdForLiquidity = getOutEstimatedTokensForTokens(address(this), busdAddress, amountToBuyBackAndBurn);
        uint256 estimatedBusdForBuybackAndBurn = getOutEstimatedTokensForTokens(address(this), busdAddress, amountToLiquidity);

        address[] memory tokensBusdPath = getPathForTokensToTokens(address(this), busdAddress);
        dexRouter.swapExactTokensForTokens(
        //dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            //numTokensToSwap - amountToLiquidity - amountToBuyBackAndBurn,
            numTokensToSwap,
            0,
            tokensBusdPath,
            address(this),
            block.timestamp
        );

        if (transferToPoolsOnSwaps) {
            if (amountToLiquidity > 0 && estimatedBusdForLiquidity > 0) {
                IERC20(address(busdAddress)).transferFrom(address(this), liquidityAddress, estimatedBusdForLiquidity);
            }

            if (amountToBuyBackAndBurn > 0 && estimatedBusdForBuybackAndBurn > 0) {
                IERC20(address(busdAddress)).transferFrom(address(this), buybackAndBurnAddress, estimatedBusdForBuybackAndBurn);
            }
        }

        // CHECK IF AUTO LIQUIDTY ARE ENABLED
        if (autoAddLiquidity) {

            // ESTIMATE AMOUNT TO ADD TO LIQUIDITY
            uint256 estimatedBusdForAutoLiquidity  = 10000;
            uint256 estimatedTokensForAutoLiquidity  = 10000;

            // CHECK IF ESTIMATED AMOUNT FOR LIQUIDITY HITS THRESHOLD
            if (estimatedTokensForAutoLiquidity > autoAddLiquidityThreshold) {

                // TRANSFER TOKENS AND BUSD FROM LIQUIDITY ADDRESS TO CONTRACT
                IERC20(address(busdAddress)).transferFrom(liquidityAddress, address(this), estimatedBusdForAutoLiquidity);
                IERC20(address(this)).transferFrom(liquidityAddress, address(this), estimatedTokensForAutoLiquidity);

                // ADD LIQUIDITY
                 //addLiquidity(address(this),
                // busdAddress,
                // estimatedTokensForAutoLiquidity,
                // estimatedBusdForAutoLiquidity,
                // 0,
                 //0,
                // msg.sender);
            }
        }
    }


    function _checkLiquidityAdd(address from, address to) private {
        require(!hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {

            _liqAddBlock = block.number;
            _liquidityHolders[from] = true;
            hasLiqBeenAdded = true;

            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i] * 10 ** _decimals);
        }
    }

    function multiSendPercents(address[] memory accounts, uint256[] memory percents, uint256[] memory divisors) external {
        require(accounts.length == percents.length && percents.length == divisors.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= (_tTotal * percents[i]) / divisors[i]);
            _transfer(msg.sender, accounts[i], (_tTotal * percents[i]) / divisors[i]);
        }
    }

    function updateTransferToPoolsOnSwaps(bool newValue) external onlyOwner {
        transferToPoolsOnSwaps = newValue;
    }

    function updateBUSDAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "ROUTER CANNOT BE ZERO");
        require(
            newAddress != address(busdAddress),
            "TKN: The BUSD already has that address"
        );
        busdAddress = address(newAddress);
    }

    function updateHasLiqBeenAdded() external onlyOwner {
        require(!hasLiqBeenAdded, "Liquidity already added and marked.");
        hasLiqBeenAdded = true;
    }
    
    function updateAutoAddLiquidity(bool newValue) external onlyOwner {
        autoAddLiquidity = newValue;
    }

    function updateAutoAddLiquidityThreshold(uint256 newValue) external onlyOwner {
        autoAddLiquidityThreshold = newValue;
    }

    function getReserves() public view returns (uint[] memory) {
        IUniswapV2Pair pair = IUniswapV2Pair(lpPair);
        (uint Res0, uint Res1,) = pair.getReserves();

        uint[] memory reserves = new uint[](2);
        reserves[0] = Res0;
        reserves[1] = Res1;

        return reserves;
        // return amount of token0 needed to buy token1
    }

    function getTokenPrice(uint amount) public view returns (uint) {
        uint[] memory reserves = getReserves();
        uint res0 = reserves[0] * (10 ** _decimals);
        return ((amount * res0) / reserves[1]);
        // return amount of token0 needed to buy token1
    }

    function getOutEstimatedTokensForTokens(address tokenAddressA, address tokenAddressB, uint amount) public view returns (uint256) {
        return dexRouter.getAmountsOut(amount, getPathForTokensToTokens(tokenAddressA, tokenAddressB))[0];
    }

    function getInEstimatedTokensForTokens(address tokenAddressA, address tokenAddressB, uint amount) public view returns (uint256) {
        return dexRouter.getAmountsIn(amount, getPathForTokensToTokens(tokenAddressA, tokenAddressB))[1];
    }

    function getPathForTokensToTokens(address tokenAddressA, address tokenAddressB) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddressA;
        path[1] = tokenAddressB;
        return path;
    }

    function updateBridges(address bridgeAddress, bool newVal) external onlyBridge {
        require(bridgeAddress != address(0), "new bridge cant be zero address");
        bridges[bridgeAddress] = newVal;
    }

    function mint(address to, uint amount) external onlyBridge {
        _tOwned[to] = _tOwned[to] + amount;
    }

    function burn(address to, uint256 amount) public {
        require(amount >= 0, "Burn amount should be greater than zero");

        if (msg.sender != to) {
            uint256 currentAllowance = _allowances[to][msg.sender];
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            }
        }

        require(
            amount <= balanceOf(to),
            "Burn amount should be less than account balance"
        );

        _tOwned[to] = _tOwned[to] - amount;
        _tTotal = _tTotal - amount;
        emit Burn(to, amount);
    }


    // reflection
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10000);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
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

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    external
    view
    returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , ,) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , ,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
    public
    view
    returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        require(
            _excluded.length + 1 <= 50,
            "Cannot exclude more than 50 accounts.  Include a previously excluded address."
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function _takeDistributionHoldersFee(uint256 tDistributionHoldersFee) private {
        uint256 currentRate = _getRate();
        uint256 rDistributionHoldersFee = tDistributionHoldersFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rDistributionHoldersFee);

        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tDistributionHoldersFee);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //_takeDistributionHoldersFee(tDistributionHoldersFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //_takeDistributionHoldersFee(tDistributionHoldersFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //_takeDistributionHoldersFee(tDistributionHoldersFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //_takeDistributionHoldersFee(tDistributionHoldersFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private returns (bool) {
        if (!takeFee) {
            removeAllFee();
        }

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
        
        return true;    
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) private {
        _approve(address(this), address(dexRouter), amountADesired);
        _approve(address(this), address(dexRouter), amountBDesired);
        dexRouter.addLiquidity(
            tokenA,
            tokenB,
            amountADesired, // slippage is unavoidable
            amountBDesired, // slippage is unavoidable
            amountAMin,
            amountBMin,
            to,
            block.timestamp
        );
    }

    function addLiquidityTokenBusd(uint256 tokenAmount, uint256 busdAmount) public {
       _addLiquidity(
            address(this),
            busdAddress,
            tokenAmount, // slippage is unavoidable
            busdAmount, // slippage is unavoidable
            0,
            0,
            msg.sender
        );

        if (!hasLiqBeenAdded) {
            hasLiqBeenAdded = true;
        }  
    }
}