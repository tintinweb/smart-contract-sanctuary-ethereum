// SPDX-License-Identifier: MIT
// ❀❀❀

/*❀

This is a relaunch due to incorrect socials on the last contract
and trading was unexpectantly enabled after adding liquidity.
Both are fixed now. Everyone will be refunded from the last launch.

Website ❀ https: // otakusenpai.xyz/

Telegram ❀ https: // t.me/otakusenpaieth

❀*/

pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;  //  silence state mutability warning without generating bytecode - see https: // github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the cal ler's tokens.
     *
     * Returns a boolean value indicating whether the op eration succeeded.
     *
     * IMPORTANT: Beware that changing an allowan ce with this method brings the risk
     * that someone may  use both the old and the new allowance by unfortunate
     * transaction ordering. One  possible solution to mitigate this race
     * condition is to first reduce the spe nder's allowance to 0 and set the
     * desired valu  afterwards:
     * https: // github.co m/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` toke ns from `sender` to `recipient` using the
     * allowance mechanism. `am ount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `v alue` tokens are moved from one account (`from`) to
     * anot her (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the all owance of a `spender` for an `owner` is set by
     * a call to {approve}. `va lue` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

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
}

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
         //  Gas optimization: this is cheaper than requiring 'a' not being zero, but the
         //  benefit is lost if 'b' is also tested.
         //  See: https: // github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
         //  assert(a == b * c + a % b);  //  There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

         //  Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
         //  Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

         //  Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
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

contract OtakuSenpai is ERC20, Ownable {
      using SafeMath for uint256;

      IUniswapV2Router02 public immutable uniswapV2Router;
      address public immutable uniswapV2Pair;

      bool private swapping;

      uint256 public swapTokensAtAmount;
      uint256 public maxTransactionAmount;

      uint256 public liquidityActiveBlock = 0;  //  0 means liquidity is not active yet
      uint256 public tradingActiveBlock = 0;  //  0 means trading is not active

      bool public tradingActive = false;
      bool public limitsInEffect = true;
      bool public swapEnabled = false;


      address public constant burnWallet =
            0x000000000000000000000000000000000000dEaD;
      address public marketingWallet = 0xC8555F805FaD29c774b540a7D450c98a2b5Ca073;

      uint256 public constant feeDivisor = 1000;

      uint256 public marketingBuyFee;
      uint256 public totalBuyFees;

      uint256 public marketingSellFee;
      uint256 public totalSellFees;

      uint256 public tokensForFees;
      uint256 public tokensForMarketing;


      bool public transferDelayEnabled = true;
      uint256 public maxWallet;


      mapping(address => bool) private _isExcludedFromFees;
      mapping(address => bool) public _isExcludedMaxTransactionAmount;

      mapping(address => bool) public automatedMarketMakerPairs;


      event ExcludeFromFees(address indexed account, bool isExcluded);
      event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

      event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

      event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
      );

      constructor() ERC20("Otaku Senpai", "OTAKU") {
            uint256 totalSupply = 1 * 1e9 * 1e18;

            swapTokensAtAmount = (totalSupply * 1) / 10000;  //  0.01% swap tokens amount
            maxTransactionAmount = (totalSupply * 10) / 1000;  //  1% maxTransactionAmountTxn
            maxWallet = (totalSupply * 20) / 1000;  //  2% maxWallet

            marketingBuyFee = 30;  //  3%
            totalBuyFees = marketingBuyFee; 

            marketingSellFee = 20;  //  2%
            totalSellFees = marketingSellFee;


            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
                  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            );

             //  Create a uniswap pair for this new token
            address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                  .createPair(address(this), _uniswapV2Router.WETH());

            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;

            _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

             //  exclude from paying fees or having max transaction amount
            excludeFromFees(owner(), true);
            excludeFromFees(address(this), true);
            excludeFromFees(address(0xdead), true);
            excludeFromFees(address(_uniswapV2Router), true);
            excludeFromFees(address(marketingWallet), true);

            excludeFromMaxTransaction(owner(), true);
            excludeFromMaxTransaction(address(this), true);
            excludeFromMaxTransaction(address(0xdead), true);
            excludeFromMaxTransaction(address(marketingWallet), true);

            _createInitialSupply(address(owner()), totalSupply);
      }

      receive() external payable {}

      function enableTrading() external onlyOwner {
            require(!tradingActive, "Cannot re-enable trading");
            tradingActive = true;
            swapEnabled = true;
            tradingActiveBlock = block.number;
      }

      function excludeFromMaxTransaction(address updAds, bool isEx)
            public
            onlyOwner
      {
            _isExcludedMaxTransactionAmount[updAds] = isEx;
      }

       //  only use to disable contract sales if absolutely necessary (emergency use only)
      function updateSwapEnabled(bool enabled) external onlyOwner {
            swapEnabled = enabled;
      }

      function excludeFromFees(address account, bool excluded) public onlyOwner {
            _isExcludedFromFees[account] = excluded;

            emit ExcludeFromFees(account, excluded);
      }

      function excludeMultipleAccountsFromFees(
            address[] calldata accounts,
            bool excluded
      ) external onlyOwner {
            for (uint256 i = 0; i < accounts.length; i++) {
                  _isExcludedFromFees[accounts[i]] = excluded;
            }

            emit ExcludeMultipleAccountsFromFees(accounts, excluded);
      }

      function setAutomatedMarketMakerPair(address pair, bool value)
            external
            onlyOwner
      {
            require(
                  pair != uniswapV2Pair,
                  "The Uniswap pair cannot be removed from automatedMarketMakerPairs"
            );

            _setAutomatedMarketMakerPair(pair, value);
      }

      function _setAutomatedMarketMakerPair(address pair, bool value) private {
            automatedMarketMakerPairs[pair] = value;
            emit SetAutomatedMarketMakerPair(pair, value);
      }

      function isExcludedFromFees(address account) external view returns (bool) {
            return _isExcludedFromFees[account];
      }

      function _transfer(
            address from,
            address to,
            uint256 amount
      ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");


            if (amount == 0) {
                  super._transfer(from, to, 0);
                  return;
            }

            if (!tradingActive) {
                  require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active yet."
                  );
            }

            if (limitsInEffect) {
                  if (
                        from != owner() &&
                        to != owner() &&
                        to != address(0) &&
                        to != address(0xdead) &&
                        !swapping
                  ) {
                        if (!tradingActive) {
                              require(
                                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                                    "Trading is not active."
                              );
                        }

                         //    when buy
                        if (
                              automatedMarketMakerPairs[from] &&
                              !_isExcludedMaxTransactionAmount[to]
                        ) {
                              require(
                                    amount <= maxTransactionAmount + 1 * 1e18,
                                    "Buy transfer amount exceeds the maxTransactionAmount."
                              );
                              require(
                                    amount + balanceOf(to) <= maxWallet,
                                    "Max wallet exceeded"
                              );
                        }
                         //    when sell
                        else if (
                              automatedMarketMakerPairs[to] &&
                              !_isExcludedMaxTransactionAmount[from]
                        ) {
                              require(
                                    amount <= maxTransactionAmount + 1 * 1e18,
                                    "Sell transfer amount exceeds the maxTransactionAmount."
                              );
                        } else if (!_isExcludedMaxTransactionAmount[to]) {
                              require(
                                    amount + balanceOf(to) <= maxWallet,
                                    "Max wallet exceeded"
                              );
                        }
                  }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (
                  canSwap &&
                  swapEnabled &&
                  !swapping &&
                  !automatedMarketMakerPairs[from] &&
                  !_isExcludedFromFees[from] &&
                  !_isExcludedFromFees[to]
            ) {
                  swapping = true;
                  swapBack();
                  swapping = false;
            }

            bool takeFee = !swapping;

             //  if any account belongs to _isExcludedFromFee account then remove the fee
            if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                  takeFee = false;
            }

            uint256 fees = 0;

             //  no taxes on transfers (non buys/sells)
            if (takeFee) {
                   //  on sell take fees, purchase token and burn it
                  if (automatedMarketMakerPairs[to] && totalSellFees > 0) {
                        fees = amount.mul(totalSellFees).div(feeDivisor);
                        tokensForFees += fees;
                        tokensForMarketing += (fees * marketingSellFee) / totalSellFees;
                  }
                   //  on buy
                  else if (automatedMarketMakerPairs[from]) {
                        fees = amount.mul(totalBuyFees).div(feeDivisor);
                        tokensForFees += fees;
                        tokensForMarketing += (fees * marketingBuyFee) / totalBuyFees;
                  }

                  if (fees > 0) {
                        super._transfer(from, address(this), fees);
                  }

                  amount -= fees;
            }

            super._transfer(from, to, amount);
      }

      function swapTokensForEth(uint256 tokenAmount) private {
             //  generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            _approve(address(this), address(uniswapV2Router), tokenAmount);

             //  make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                  tokenAmount,
                  0,  //  accept any amount of ETH
                  path,
                  address(this),
                  block.timestamp
            );
      }

      function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
             //  approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);

             //  add the liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                  address(this),
                  tokenAmount,
                  0,  //  slippage is unavoidable
                  0,  //  slippage is unavoidable
                  address(0xdead),
                  block.timestamp
            );
      }

      function manualSwap() external onlyOwner {
            uint256 contractBalance = balanceOf(address(this));
            swapTokensForEth(contractBalance);
      }

       //  remove limits after token is stable
      function removeLimits() external onlyOwner returns (bool) {
            limitsInEffect = false;
            return true;
      }

      function swapBack() private {
            uint256 contractBalance = balanceOf(address(this));
            uint256 totalTokensToSwap = tokensForMarketing;
            bool success;

            if (contractBalance == 0 || totalTokensToSwap == 0) {
                  return;
            }

            uint256 amountToSwapForETH = contractBalance;
            swapTokensForEth(amountToSwapForETH);

            (success, ) = address(marketingWallet).call{
                  value: address(this).balance
            }("");

            tokensForMarketing = 0;
            tokensForFees = 0;
      }



}