// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";

import "./Wallet.sol";
import "./IUniswapV2Router.sol";
import "./PriceConsumerV3.sol";
import "./PoolLPToken.sol";
import "./strategies/IStrategy.sol";


contract Pool is Wallet, KeeperCompatibleInterface  {

    //address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // address private constant DAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;


    event Swapped(string swapType, uint amount, uint spent, uint bought);
    event Deposited(uint amount, uint depositLP, uint totalPortfolioLP);
    event Withdraw(uint amount, uint lpToWithdraw, uint depositTokenWithdraw);

    event PriceFeed(int price);

    IERC20 internal investToken;

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public immutable priceFeedDecimals;
    uint public lastTimeStamp;
    uint public counter;

    IUniswapV2Router uniswapV2Router;
    IPriceFeed priceFeed;
    PoolLPToken lpToken;
    IStrategy strategy;

    uint immutable portFolioPercentagePrecision = 10**18; // 8 digit precision for portfolio % calculations
    uint immutable lpPrecision = 10**18;
    uint immutable public initialLPAllocation = 100 * 10**18;


    constructor(
        address _uniswapV2RouterAddress, 
        address _priceFeedAddress, 
        address _depositTokenAddress, 
        address _investTokenAddress, 
        address _lpTokenAddress,
        address _strategyAddress,
        uint _updateInterval) public Wallet(_depositTokenAddress) {

        investToken = IERC20(_investTokenAddress);
        uniswapV2Router = IUniswapV2Router(_uniswapV2RouterAddress);
        lpToken = PoolLPToken(_lpTokenAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        strategy = IStrategy(_strategyAddress);

        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
        priceFeedDecimals = priceFeed.decimals();
    }

    // the LP tokens allocations to the user
    function portfolioAllocation() public view returns (uint) {
        //return portfolioLPAllocation[msg.sender];
        return lpToken.balanceOf(msg.sender);
    }

    function portfolioPercentage() public view returns (uint) {
        // the % of the portfolio of the user (with 'portFolioPercentagePrecision' digits precision)
        uint portFolioPercentage = portFolioPercentagePrecision * lpToken.balanceOf(msg.sender) / lpToken.totalSupply();
        return portFolioPercentage;
    }

    function portfolioValue() public view returns (uint) {
        // the value of the portfolio allocated to the user
        uint portFolioValue = totalPortfolioValue() * portfolioPercentage() / portFolioPercentagePrecision;
        return portFolioValue;
    }


    // returns the portfolio value in depositTokens
    function totalPortfolioValue() public view returns(uint) {
        uint depositTokens = depositToken.balanceOf(address(this));
        uint investTokens = investToken.balanceOf(address(this));
      
        int investTokenPrice = priceFeed.getLatestPrice();
        require (investTokenPrice >= 0, "Invest token price can't be negative");

        // portoflio value is the sum of deposit token value and invest token value
        uint value = depositTokens + (investTokens * uint(investTokenPrice) / priceFeedDecimals);

        return value;
    }

    function latestPrice() public view returns(int) {
        return priceFeed.getLatestPrice();
    }

    // returns the deposit token balance of the pool
    function depositTokenBalance() external view returns(uint256) {
        return depositToken.balanceOf(address(this));
    }

    // returns the invest token balance of the pool
    function investTokenBalance() external view returns(uint256) {
        return investToken.balanceOf(address(this));
    }

    // User deposits 'amount' of depositTokens into the pool
    function deposit(uint amount) public override {
        super.deposit(amount);

        ///// first deposit => allocate the inital LP tokens amount to the user
        if (lpToken.totalSupply() == 0) {
            lpToken.mint(msg.sender, initialLPAllocation);

            emit Deposited(amount, initialLPAllocation, initialLPAllocation);
            return;
        }

        ///// if already have allocated LP tokens => calculate the additional LP tokens for this deposit

        // calculate portfolio % of the deposit (using lpPrecision digits precision)
        uint portFolioValue = totalPortfolioValue();
        uint portFolioPercentage = lpPrecision * amount / portFolioValue;

        // calculate the amount of LP tokens for the deposit so that they represent 
        // a % of the existing LP tokens equivalent to the % value of this deposit to the whole portfolio value.
        // 
        // X := P * T / (1 - P)  
        //      X: additinal LP toleks to allocate to the user to account for this deposit
        //      P: Percentage of portfolio accounted by this deposit
        //      T: total LP tokens allocated before this deposit
  
        uint depositLPTokens = (portFolioPercentage * lpToken.totalSupply()) / ((1 * lpPrecision) - portFolioPercentage);
        lpToken.mint(msg.sender, depositLPTokens);

        emit Deposited(amount, depositLPTokens, lpToken.totalSupply());
    }

    // Withdraw 'amount' of depositTokens from the pool
    function withdraw(uint amount) public override {

        require (amount > 0, "Amount to withdraw should be > 0");

        // Ensure the user account has enough funds in the Pool
        uint pv = portfolioValue(); // the value of the user portfolio
        require (pv >= amount, "Withdrawal limits exceeded");

        // the % of the whole pool to be withdrawn
        uint withdrawPerc = portFolioPercentagePrecision * amount / totalPortfolioValue();

        // calculte the LP amount to burn
        uint lpToBurn = lpToken.totalSupply() * withdrawPerc / portFolioPercentagePrecision;
        require (lpToBurn > 0, "LP to withdraw is 0");
        require (lpToBurn <= lpToken.balanceOf(msg.sender), "LP to withdraw more than account balance");

        // burn the user LP
        lpToken.burn(msg.sender, lpToBurn);

        // calculate amount of depositTokens & investTokens to withdraw
        uint depositTokens = depositToken.balanceOf(address(this));
        uint investTokens = investToken.balanceOf(address(this));

        uint withdrawDepositTokensAmount = depositTokens * withdrawPerc / portFolioPercentagePrecision;
        uint withdrawInvestTokensTokensAmount = investTokens * withdrawPerc / portFolioPercentagePrecision;

        if (withdrawInvestTokensTokensAmount > 0) {
            // swap some investTokens into depositTokens to be withdrawn
            uint256 amountMin = getAmountOutMin(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount);
            swap(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount, amountMin, address(this));
        }

        // determine how much depositTokens where swapped
        uint depositTokensAfterSwap = depositToken.balanceOf(address(this));
        require(depositTokensAfterSwap >= depositTokens, "Deposit tokens after swap should not be less than amount before the swap");
        uint depositTokensSwapped = depositTokensAfterSwap - depositTokens;

        // transfer depositTokens to the user
        uint depositTokenWithdraw = withdrawDepositTokensAmount + depositTokensSwapped;        
        super.withdraw(depositTokenWithdraw);
    }




    /// INVESTMENT STRATEGY

    function invest() public {

        // evaluate strategy to see if we should BUY or SELL
        (StrategyAction action, uint amountIn) = strategy.evaluate(priceFeed.getLatestPrice(), priceFeed.getLatestTimestamp());

        if (action == StrategyAction.NONE || amountIn == 0) {
            // No rebalancing needed
            emit Swapped("None", 0, 0, 0);
            return;
        }

        // We should BUY or SELL
        address tokenIn;
        address tokenOut;

        if (action == StrategyAction.BUY) {
            tokenIn = address(depositToken);
            tokenOut = address(investToken);
        } else if (action == StrategyAction.SELL) {
            tokenIn = address(investToken);
            tokenOut = address(depositToken);
        }

        // balances before swap
        uint256 depositTokenBalanceBefore = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceBefore = investToken.balanceOf(address(this));

        // perform swap
        uint256 amountMin = getAmountOutMin(tokenIn, tokenOut, amountIn);
        swap(tokenIn, tokenOut, amountIn, amountMin, address(this));

        // balances after swap
        uint256 depositTokenBalanceAfter = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceAfter = investToken.balanceOf(address(this));

        uint256 spent;
        uint256 bought;
        string memory swapType;
        
        if (action == StrategyAction.BUY) {
            swapType = "BUY";
            spent = depositTokenBalanceBefore - depositTokenBalanceAfter;
            bought = investTokenBalanceAfter - investTokenBalanceBefore;
        } else if (action == StrategyAction.SELL) {
            swapType = "SELL";
            spent = investTokenBalanceBefore - investTokenBalanceAfter;
            bought = depositTokenBalanceAfter - depositTokenBalanceBefore;
        }

        emit Swapped(swapType, amountIn, spent, bought);
        
    }


    /// TOKEN SWAP FUNCTIONALITY

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin,address _to) internal {

        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        IERC20(_tokenIn).approve(address(uniswapV2Router), _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        uniswapV2Router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    //this function will return the minimum amount from a swap
    //input the 3 parameters below and it will return the minimum amount out
    //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint256) {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = uniswapV2Router.getAmountsOut(_amountIn, path);
        require(amountOutMins.length >= path.length , "Invalid amountOutMins size");

        return amountOutMins[path.length - 1];
    }


    // UPKEEP FUNCTIONALITY

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
            invest();
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

enum StrategyAction { BUY, SELL, NONE }

interface IStrategy {

    function description() external view returns(string memory _);
    function name() external view returns(string memory _);

    function evaluate(int price, uint time) external view returns(StrategyAction action, uint amount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    IERC20 internal depositToken;

    uint public totalDeposited = 0;
    uint public totalWithdrawn = 0;

    // depositToken token balances
    mapping (address => uint) public deposits;
    mapping (address => uint) public withdrawals;

    // users that deposited depositToken tokens into their balances
    address[] internal usersArray;
    mapping (address => bool) internal users;


    constructor(address _depositTokenAddress) public {
        depositToken = IERC20(_depositTokenAddress);
    }


    function getDeposits() external view returns (uint) {
        return deposits[msg.sender];
    }

    function getWithdrawals() external view returns (uint) {
        return withdrawals[msg.sender];
    }


    function deposit(uint amount) public virtual {
        require(amount > 0, "Deposit amount is 0");
        require(depositToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance to deposit");

        deposits[msg.sender] = deposits[msg.sender] + amount;
        totalDeposited = totalDeposited + amount;
        // remember addresses that deposited tokens
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersArray.push(msg.sender);
        }
        depositToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint amount) public virtual {
        require(amount > 0, "Withdraw amount is 0");
        require(depositToken.balanceOf(address(this)) >= amount, "Withdrawal amount exceeds balance");

        withdrawals[msg.sender] = withdrawals[msg.sender] + amount;
        totalWithdrawn = totalWithdrawn + amount;

        depositToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}

// This example code is designed to quickly deploy an example contract using Remix.

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IPriceFeed {
    function getLatestPrice() external view returns (int);
    function getLatestTimestamp() external view returns (uint);
    function decimals() external view returns (uint);
}


contract PriceConsumerV3 is IPriceFeed {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor(address _priceFeed) public {
        //priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public override view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    /**
     * Returns the latest price
     */
    function getLatestTimestamp() public override view returns (uint) {
        (
            /*uint80 roundID*/,
            /*int price*/,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return timeStamp;
    }

    function decimals() public override view returns (uint) {
        return priceFeed.decimals();
    }
}

pragma solidity ^0.6.6;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";

/**
 * The LP Token of the pool.
 * New tokens get minted by the Pool when users deposit into the pool
 * and get burt when users withdraw from the pool.
 * Only the Pool contract should be able to mint/burn these tokens.
 */

contract PoolLPToken is ERC20, MinterRole {

    constructor () public ERC20("Pool LP Token", "PoolLP") {}

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address to, uint256 value) public onlyMinter returns (bool) {
        _burn(to, value);
        return true;
    }

}

pragma solidity ^0.6.6;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(!has(role, account), "Account already has role");

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(has(role, account), "Account does not have role");

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "0x0 account");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Non minter call");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IUniswapV2Router {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, //amount of tokens we are sending in
        uint amountOutMin, //the minimum amount of tokens we want out of the trade
        address[] calldata path,  //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address to,  //this is the address we are going to send the output tokens to
        uint deadline //the last time that the trade is valid for
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}