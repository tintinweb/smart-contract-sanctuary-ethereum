/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// File: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol

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

// File: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

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

// File: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol 


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: tomokachieth.sol


pragma solidity ^0.8.9;




contract Tomokachi is Ownable, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromWalletHoldingLimit;
    mapping(address => bool) private _isAutomaticMarketMaker;
    uint256 public _decimals = 18;
    uint256 public _totalSupply = 100 * 10**6 * 10**_decimals;
    string private _name = "Tomokachi";
    string private _symbol = "TMK";

    address public immutable DeadWalletAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public MarketingWalletAddress =
        payable(0x7b25845A8d16ffF240cdB0CF8cB27fCE681B25E5);
    address payable public TeamWalletAddress =
        payable(0x1BE1255A0cF21dda1a85ac155E79d71558B41671);
    address payable public SeedWalletAddress =
        payable(0xCd4E503F558bE452cd47f574A7ae860Ab1f55E64);

    uint256 internal _liquidityFee = 100;
    uint256 internal _BurnFee = 100;
    uint256 internal _TeamFee = 200;
    uint256 internal _MarketingFee = 350;
    uint256 internal _SeedFee = 50;

    uint256 public TotalTaxFee =
        _liquidityFee + _BurnFee + _TeamFee + _MarketingFee + _SeedFee;

    uint256 feeDenominator = 10_000;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradeEnabled = false;

    uint256 public numTokensSellToAddToLiquidity = 1 * 10**5 * 10**_decimals;
    uint256 public _maxWalletHoldingLimit = 6 * 10**6 * 10**_decimals;

    event MaxWalletHoldingAmountUpdated(uint256 updatedMaxWalletHoldingAmount);
    event AutomaticMarketMakerPairUpdated(address account, bool status);
    event TaxFeeUpdated(uint256 TaxFees);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ETHReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _balances[msg.sender] = _totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D//0xD99D1c33F9fC3444f8101754aBC46c52416550D1//0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee and Wallet holding Limits
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromWalletHoldingLimit[address(this)] = true;
        _isExcludedFromWalletHoldingLimit[uniswapV2Pair] = true;
        _isExcludedFromWalletHoldingLimit[MarketingWalletAddress] = true;
        _isExcludedFromWalletHoldingLimit[SeedWalletAddress] = true;
        _isExcludedFromWalletHoldingLimit[TeamWalletAddress] = true;
        _isExcludedFromWalletHoldingLimit[msg.sender] = true;
        _isAutomaticMarketMaker[uniswapV2Pair] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function enableTrade(bool _cond) public onlyOwner {
        tradeEnabled = _cond;
    }    

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
            "IERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromTax(address add) external view returns (bool) {
        return _isExcludedFromFee[add];
    }

    function isExcludedFromWalletLimit(address WalletAddress)
        external
        view
        returns (bool)
    {
        return _isExcludedFromWalletHoldingLimit[WalletAddress];
    }

    function excludeFromMaxWalletHoldingLimit(address account)
        external
        onlyOwner
    {
        _isExcludedFromWalletHoldingLimit[account] = true;
    }

    function includeInMaxWalletHoldingLimit(address account)
        external
        onlyOwner
    {
        require(
            account != uniswapV2Pair,
            "You can't play with Liquidity pair address"
        );
        _isExcludedFromWalletHoldingLimit[account] = false;
    }

    function UpdateMaxWalletHoldingLimit(uint256 maxWalletHoldingAmount)
        external
        onlyOwner
    {
        require(
            maxWalletHoldingAmount * 10**_decimals >= 1_000_000 * 10**_decimals,
            "Amount should be greater or equal to 1 Millin Tokens"
        );
        _maxWalletHoldingLimit = maxWalletHoldingAmount * 10**_decimals;
        emit MaxWalletHoldingAmountUpdated(_maxWalletHoldingLimit);
    }

    function isAutomaticMarketMaker(address account)
        external
        view
        returns (bool)
    {
        return _isAutomaticMarketMaker[account];
    }

    function setNewLiquidityPair(address addNewAMM, bool status)
        external
        onlyOwner
    {
        _isAutomaticMarketMaker[addNewAMM] = status;
        emit AutomaticMarketMakerPairUpdated(addNewAMM, status);
    }

    function UpdateWallets(
        address payable newMarketingWallet,
        address payable newTeamWallet,
        address payable newSeedWallet
    ) external onlyOwner {
        require(
            newMarketingWallet != address(0) &&
                newTeamWallet != address(0) &&
                newSeedWallet != address(0),
            "You can't set zero address"
        );
        MarketingWalletAddress = newMarketingWallet;
        TeamWalletAddress = newTeamWallet;
        SeedWalletAddress = newSeedWallet;
    }

    function UpdateTaxFees(
        uint256 newLiquidityFee,
        uint256 newMarketingFee,
        uint256 newTeamFee,
        uint256 newSeedFee,
        uint256 newBurnFee
    ) external onlyOwner {
        require(
            newLiquidityFee +
                newMarketingFee +
                newTeamFee +
                newBurnFee +
                newSeedFee <=
                800,
            "you can't set more than 8%"
        );
        _liquidityFee = newLiquidityFee;
        _MarketingFee = newMarketingFee;
        _TeamFee = newTeamFee;
        _BurnFee = newBurnFee;
        _SeedFee = newSeedFee;
        TotalTaxFee =
            _liquidityFee +
            _BurnFee +
            _TeamFee +
            _MarketingFee +
            _SeedFee;
        emit TaxFeeUpdated(TotalTaxFee);
    }

    function UpdateNoOfTokensSellToGetReward(uint256 thresholdValue)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = thresholdValue * 10**_decimals;
        emit MinTokensBeforeSwapUpdated(numTokensSellToAddToLiquidity);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "IERC20: transfer amount exceeds allowance"
        );
        return true;
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(
            recipient != address(0),
            "IERC20: transfer to the zero address"
        );
        require(_balances[sender] >= amount, "You don't have enough balance");

        if (
            !_isExcludedFromWalletHoldingLimit[recipient] && sender != owner()
        ) {
            require(
                balanceOf(recipient) + amount <= _maxWalletHoldingLimit,
                "Wallet Holding limit exceeded"
            );
        }
        if(sender == owner()){
            _balances[recipient]+=amount;
            _balances[sender]-=amount;
            emit Transfer(sender,recipient,amount);
            return;
        }

        uint256 totalTax = 0;
        uint256 BurnTax = 0;

        if (
            _isAutomaticMarketMaker[sender] ||
            _isAutomaticMarketMaker[recipient]
        ) {
            if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
                totalTax = 0;
                BurnTax = 0;
            } else {
                require(tradeEnabled,"trade is not yet enabled");
                totalTax =
                    (amount *
                        (_liquidityFee + _TeamFee + _SeedFee + _MarketingFee)) /
                    (feeDenominator);
                BurnTax = (amount * _BurnFee) / feeDenominator;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            recipient == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            balanceOf(uniswapV2Pair) > 0
        ) {
            if (overMinTokenBalance) {
                contractTokenBalance = numTokensSellToAddToLiquidity;

                uint256 remainingLiquidityToken;
                if (_MarketingFee + _SeedFee + _TeamFee + _liquidityFee > 0) {
                    remainingLiquidityToken =
                        (contractTokenBalance *
                            (_MarketingFee + _SeedFee + _TeamFee)) /
                        (_MarketingFee + _SeedFee + _TeamFee + _liquidityFee);
                }

                uint256 liquidityToken;
                if (_liquidityFee > 0) {
                    liquidityToken =
                        contractTokenBalance -
                        (remainingLiquidityToken);
                } else {
                    if (_MarketingFee + _SeedFee + _TeamFee > 0) {
                        remainingLiquidityToken = contractTokenBalance;
                    }
                }

                // Swap Tokens and Send to Different Addresses
                if (_MarketingFee + _SeedFee + _TeamFee > 0) {
                    swapTokens(remainingLiquidityToken);
                }
                if (liquidityToken > 0) {
                    // Remove Hate Swap and Liquidity by breaking Token in proportion
                    swapAndLiquify(liquidityToken);
                }
            }
        }

        uint256 amountReceived = amount - (totalTax + BurnTax);
        _balances[address(this)] += totalTax;
        _balances[DeadWalletAddress] += BurnTax;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] += amountReceived;
        if (BurnTax > 0) {
            emit Transfer(sender, DeadWalletAddress, BurnTax);
        }
        if (totalTax > 0) {
            emit Transfer(sender, address(this), totalTax);
        }
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapTokens(uint256 _contractTokenBalance) private lockTheSwap {
        uint256 combineFee = _MarketingFee + _TeamFee + _SeedFee;
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(_contractTokenBalance);
        uint256 transferredBalance = address(this).balance - (initialBalance);
        uint256 marketingBalance = (transferredBalance * (_MarketingFee)) /
            (combineFee);
        uint256 TeamBalance = (transferredBalance * (_TeamFee)) / (combineFee);
        uint256 seedBalance = (transferredBalance * (_SeedFee)) / (combineFee);
        if (marketingBalance > 0) {
            transferToAddressETH(MarketingWalletAddress, marketingBalance);
        }
        if (TeamBalance > 0) {
            transferToAddressETH(TeamWalletAddress, TeamBalance);
        }
        if (seedBalance > 0) {
            transferToAddressETH(SeedWalletAddress, seedBalance);
        }
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForETH(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - (initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);

        if (address(this).balance > 0) {
            MarketingWalletAddress.transfer(address(this).balance);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}