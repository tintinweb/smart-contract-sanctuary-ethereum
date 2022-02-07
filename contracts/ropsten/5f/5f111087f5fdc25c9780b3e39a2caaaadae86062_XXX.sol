/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Only owner can access!"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

    contract XXX is Context, IERC20, Ownable {
    mapping(address => uint256) private _reflectionBalances;
    mapping(address => uint256) private _tokenBalances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;
    mapping(address => mapping(address => uint256)) private _allowances;
    IUniswapV2Router02 internal _uniswapV2Router;
    address internal _uniswapV2Pair;
    address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;
    uint8 private _taxBurn = 10;
    uint8 private _taxReward = 10;
    uint8 private _taxLiquify = 10;
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100 * (10**6) * (10**_decimals);
    uint256 private _currentSupply;
    uint256 private _reflectionTotal;
    uint256 private _totalRewarded;
    uint256 private _totalBurnt;
    uint256 private _totalTokensLockedInLiquidity;
    uint256 private _totalETHLockedInLiquidity;
    uint256 private _minTokensBeforeSwap = (10**3) * (10**_decimals);
    string private _name = "XXX";
    string private _symbol = "XXX";
    bool private _inSwapAndLiquify;
    bool private _autoSwapAndLiquifyEnabled;
    bool private _autoBurnEnabled;
    bool private _rewardEnabled;
    // Prevent reentrancy.
    modifier lockTheSwap() {
        require(!_inSwapAndLiquify);
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event Burn(address from, uint256 amount);

    event TaxBurnUpdate(uint8 previousTax, uint8 currentTax);
    
    event TaxRewardUpdate(uint8 previousTax, uint8 currentTax);
    
    event TaxLiquifyUpdate(uint8 previousTax, uint8 currentTax);

    event MinTokensBeforeSwapUpdated(uint256 previous, uint256 current);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );
    
    event ExcludeAccountFromReward(address account);
    
    event IncludeAccountInReward(address account);
    
    event ExcludeAccountFromFee(address account);
    
    event IncludeAccountInFee(address account);
    
    event EnabledAutoBurn();
    
    event EnabledReward();
    
    event EnabledAutoSwapAndLiquify();
    
    event DisabledAutoBurn();
    
    event DisabledReward();
    
    event DisabledAutoSwapAndLiquify();
    
    event Airdrop(uint256 amount);

    struct ValuesFromAmount {
    // Amount of tokens for to transfer.
        uint256 amount;
        // Amount tokens charged for burning.
        uint256 tBurnFee;
        // Amount tokens charged to reward.
        uint256 tRewardFee;
        // Amount tokens charged to add to liquidity.
        uint256 tLiquifyFee;
        // Amount tokens after fees.
        uint256 tTransferAmount;
        // Reflection of amount.
        uint256 rAmount;
        // Reflection of burn fee.
        uint256 rBurnFee;
        // Reflection of reward fee.
        uint256 rRewardFee;
    // Reflection of liquify fee.
        uint256 rLiquifyFee;
    // Reflection of transfer amount.
        uint256 rTransferAmount;
    }

    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() {
    _currentSupply = _totalSupply;
    _reflectionTotal = (~uint256(0) - (~uint256(0) % _totalSupply));
        // Mint
    _reflectionBalances[_msgSender()] = _reflectionTotal;
        // exclude owner and this contract from fee.
    excludeAccountFromFee(owner());
    excludeAccountFromFee(address(this));
        // exclude owner, burnAccount, and this contract from receiving rewards.
    _excludeAccountFromReward(owner());
    _excludeAccountFromReward(burnAccount);
    _excludeAccountFromReward(address(this));

        enableAutoBurn(_taxBurn);
        enableReward(_taxReward);
        enableAutoSwapAndLiquify(
            _taxLiquify,
            routerAddress,
            _minTokensBeforeSwap
        );
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    // function uniswapV2Pair() external view virtual returns (address) {
    //     return _uniswapV2Pair;
    // }
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    function currentSupply() external view virtual returns (uint256) {
        return _currentSupply;
    }
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_isExcludedFromReward[account]) return _tokenBalances[account];
        return tokenFromReflection(_reflectionBalances[account]);
    }
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function isExcludedFromReward(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromReward[account];
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function transfer(address recipient, uint256 amount)
        public
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }
        /**
     * @dev Distribute the `tRewardFee` tokens to all holders that are included in receiving reward.
     * amount received is based on how many token one owns.
     */
    function _distributeFee(uint256 rRewardFee, uint256 tRewardFee) private {
        // This would decrease rate, thus increase amount reward receive based on one's balance.
        _reflectionTotal = _reflectionTotal - rRewardFee;
        _totalRewarded += tRewardFee;
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        ValuesFromAmount memory values;
        (
            values
        ) = _getValues(amount, _isExcludedFromFee[sender]);

        if (
            _isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferFromExcluded(
                sender,
                recipient,
                values.amount,
                values.rAmount,
                values.rTransferAmount
            );
        } else if (
            !_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferToExcluded(
                sender,
                recipient,
                values.rAmount,
                values.tTransferAmount,
                values.rTransferAmount
            );
        } else if (
            !_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferStandard(sender, recipient, values.rAmount, values.rTransferAmount);
        } else if (
            _isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferBothExcluded(
                sender,
                recipient,
                amount,
                values.rAmount,
                values.tTransferAmount,
                values.rTransferAmount
            );
        } else {
            _transferStandard(sender, recipient, values.rAmount, values.rTransferAmount);
        }

        emit Transfer(sender, recipient, values.tTransferAmount);

        if (!_isExcludedFromFee[sender]) {
            _afterTokenTransfer(
                values.tBurnFee,
                values.rBurnFee,
                values.tRewardFee,
                values.rRewardFee,
                values.tLiquifyFee,
                values.rLiquifyFee
            );
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: amount exceeds balance");

        uint256 rAmount = _getRAmount(amount);

        // Transfer from account to the burnAccount
        if (_isExcludedFromReward[account]) {
            _tokenBalances[account] -= amount;
        }
        _reflectionBalances[account] -= rAmount;

        _tokenBalances[burnAccount] += amount;
        _reflectionBalances[burnAccount] += rAmount;

        _currentSupply -= amount;

        _totalBurnt += amount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
    }

    

    function _afterTokenTransfer(
        uint256 tBurnFee,
        uint256 rBurnFee,
        uint256 tRewardFee,
        uint256 rRewardFee,
        uint256 tLiquifyFee,
        uint256 rLiquifyFee
    ) internal virtual {
        // Burn
        if (_autoBurnEnabled) {
            _tokenBalances[address(this)] += tBurnFee;
            _reflectionBalances[address(this)] += rBurnFee;
            _approve(address(this), _msgSender(), tBurnFee);
            burnFrom(address(this), tBurnFee);
        }

        // Reflect
        if (_rewardEnabled) {
            _distributeFee(rRewardFee, tRewardFee);
        }

        // Add to liquidity pool
        if (_autoSwapAndLiquifyEnabled) {
            // add liquidity fee to this contract.
            _tokenBalances[address(this)] += tLiquifyFee;
            _reflectionBalances[address(this)] += rLiquifyFee;

            uint256 contractBalance = _tokenBalances[address(this)];

            // whether the current contract balances makes the threshold to swap and liquify.
            bool overMinTokensBeforeSwap = contractBalance >=
                _minTokensBeforeSwap;

            if (
                overMinTokensBeforeSwap &&
                !_inSwapAndLiquify &&
                _msgSender() != _uniswapV2Pair &&
                _autoSwapAndLiquifyEnabled
            ) {
                contractBalance = _minTokensBeforeSwap;
                swapAndLiquify(contractBalance);
            }
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            rTransferAmount;
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 rAmount,
        uint256 tTransferAmount,
        uint256 rTransferAmount
    ) private {
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + tTransferAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            rTransferAmount;
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 amount,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _tokenBalances[sender] = _tokenBalances[sender] - amount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            rTransferAmount;
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 amount,
        uint256 rAmount,
        uint256 tTransferAmount,
        uint256 rTransferAmount
    ) private {
        _tokenBalances[sender] = _tokenBalances[sender] - amount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + tTransferAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            rTransferAmount;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function _excludeAccountFromReward(address account) internal {
        require(
            !_isExcludedFromReward[account],
            "Account is already excluded."
        );

        if (_reflectionBalances[account] > 0) {
            _tokenBalances[account] = tokenFromReflection(
                _reflectionBalances[account]
            );
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);

        emit ExcludeAccountFromReward(account);
    }

    function _includeAccountInReward(address account) internal {
        require(_isExcludedFromReward[account], "Account is already included.");

        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tokenBalances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }

        emit IncludeAccountInReward(account);
    }

    function excludeAccountFromFee(address account) internal {
        require(!_isExcludedFromFee[account], "Account is already excluded.");

        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }

    function includeAccountInFee(address account) internal {
        require(_isExcludedFromFee[account], "Account is already included.");

        _isExcludedFromFee[account] = false;

        emit IncludeAccountInFee(account);
    }

    function airdrop(uint256 amount) public {
        address sender = _msgSender();
        //require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        require(
            balanceOf(sender) >= amount,
            "The caller must have balance >= amount."
        );
        ValuesFromAmount memory values;
        (values) = _getValues(amount, false);
        if (_isExcludedFromReward[sender]) {
            _tokenBalances[sender] -= amount;
        }
        _reflectionBalances[sender] -= values.rAmount;

        _reflectionTotal = _reflectionTotal - values.rAmount;
        _totalRewarded += amount;
        emit Airdrop(amount);
    }

    function reflectionFromToken(uint256 amount, bool deductTransferFee)
        internal
        view
        returns (uint256)
    {
        require(amount <= _totalSupply, "Amount must be less than supply");
        ValuesFromAmount memory values;
        (values) = _getValues(
            amount,
            deductTransferFee
        );
        return values.rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        require(
            rAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function swapAndLiquify(uint256 contractBalance) private lockTheSwap {
        // Split the contract balance into two halves.
        uint256 tokensToSwap = contractBalance / 2;
        uint256 tokensAddToLiquidity = contractBalance - tokensToSwap;

        // Contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap half of the tokens to ETH.
        swapTokensForEth(tokensToSwap);

        // Figure out the exact amount of tokens received from swapping.
        uint256 ethAddToLiquify = address(this).balance - initialBalance;

        // Add to the LP of this token and WETH pair (half ETH and half this token).
        addLiquidity(ethAddToLiquify, tokensAddToLiquidity);

        _totalETHLockedInLiquidity += address(this).balance - initialBalance;
        _totalTokensLockedInLiquidity +=
            contractBalance -
            balanceOf(address(this));

        emit SwapAndLiquify(
            tokensToSwap,
            ethAddToLiquify,
            tokensAddToLiquidity
        );
    }

    function swapTokensForEth(uint256 amount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);

        // Swap tokens to ETH
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this), // this contract will receive the eth that were swapped from the token
            block.timestamp + 60 * 1000
        );
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the ETH and token to LP.
        // The LP tokens will be sent to burnAccount.
        // No one will have access to them, so the liquidity will be locked forever.
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAccount, // the LP is sent to burnAccount.
            block.timestamp + 60 * 1000
        );
    }

// (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity)
    function _getValues(uint256 amount, bool deductTransferFee)
        private
        view
        returns (ValuesFromAmount memory
        )
    {
        ValuesFromAmount memory values;
        values.amount = amount;
        (
            values
        ) = _getTValues(values, deductTransferFee);

        (
           values
        ) = _getRValues(values,
                deductTransferFee
            );

        return (values);
    }

    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee)
        private
        view
        returns (ValuesFromAmount memory
        )
    {
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            values.tBurnFee = _calculateBurnTax(values.amount);
            values.tRewardFee = _calculateRewardTax(values.amount);
            values.tLiquifyFee = _calculateLiquifyTax(values.amount);

            // amount after fee
            values.tTransferAmount = values.amount - values.tBurnFee - values.tRewardFee - values.tLiquifyFee;
        }
        return (values);
    }

    function _getRValues(ValuesFromAmount memory values,
        bool deductTransferFee
    )
        private
        view
        returns (ValuesFromAmount memory
        )
    {
        uint256 currentRate = _getRate();

        if (deductTransferFee) {
            values.rTransferAmount = values.rAmount;
        } else {
            values.rAmount = values.amount * currentRate;
            values.rBurnFee = values.tBurnFee * currentRate;
            values.rRewardFee = values.tRewardFee * currentRate;
            values.rLiquifyFee = values.tLiquifyFee * currentRate;
            values.rTransferAmount = values.rAmount - values.rBurnFee - values.rRewardFee - values.rLiquifyFee;
        }
        return (values);
    }

    function _calculateBurnTax(uint256 amount) private view returns (uint256) {
        return (amount * _taxBurn) / (10**2);
    }

    function _calculateRewardTax(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (amount * _taxReward) / (10**2);
    }

    function _calculateLiquifyTax(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (amount * _taxLiquify) / (10**2);
    }

    function _getRAmount(uint256 amount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        return amount * currentRate;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (
                _reflectionBalances[_excludedFromReward[i]] > rSupply ||
                _tokenBalances[_excludedFromReward[i]] > tSupply
            ) return (_reflectionTotal, _totalSupply);
            rSupply = rSupply - _reflectionBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tokenBalances[_excludedFromReward[i]];
        }
        if (rSupply < _reflectionTotal / _totalSupply)
            return (_reflectionTotal, _totalSupply);
        return (rSupply, tSupply);
    }

    function enableAutoBurn(uint8 taxBurn_) public onlyOwner {
        require(!_autoBurnEnabled, "Auto burn is already enabled.");
        require(taxBurn_ > 0, "Tax must be greater than 0.");

        _autoBurnEnabled = true;
        setTaxBurn(taxBurn_);

        emit EnabledAutoBurn();
    }

    function enableReward(uint8 taxReward_) public onlyOwner {
        require(!_rewardEnabled, "Reward is already enabled.");
        require(taxReward_ > 0, "Tax must be greater than 0.");

        _rewardEnabled = true;
        setTaxReward(taxReward_);

        emit EnabledReward();
    }

    function enableAutoSwapAndLiquify(
        uint8 taxLiquify_,
        address _routerAddress,
        uint256 minTokensBeforeSwap_
    ) public onlyOwner {
        require(
            !_autoSwapAndLiquifyEnabled,
            "Auto Swap and Liquify is already enabled."
        );
        require(taxLiquify_ > 0, "Tax must be greater than 0.");

        _minTokensBeforeSwap = minTokensBeforeSwap_;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_routerAddress);

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(this),
            uniswapV2Router.WETH()
        );

        if (_uniswapV2Pair == address(0)) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }

        _uniswapV2Router = uniswapV2Router;

        // exclude uniswapV2Router from receiving reward.
        _excludeAccountFromReward(address(uniswapV2Router));
        // exclude WETH and this Token Pair from receiving reward.
        _excludeAccountFromReward(_uniswapV2Pair);

        // exclude uniswapV2Router from paying fees.
        excludeAccountFromFee(address(uniswapV2Router));
        // exclude WETH and this Token Pair from paying fees.
        excludeAccountFromFee(_uniswapV2Pair);

        // enable
        _autoSwapAndLiquifyEnabled = true;
        setTaxLiquify(taxLiquify_);

        emit EnabledAutoSwapAndLiquify();
    }

    /**
     * @dev Disables the auto burn feature.
     *
     * Emits a {DisabledAutoBurn} event.
     *
     * Requirements:
     *
     * - auto burn feature mush be enabled.
     */
    function disableAutoBurn() public onlyOwner {
        require(_autoBurnEnabled, "Auto burn  is already disabled.");

        setTaxBurn(0);
        _autoBurnEnabled = false;

        emit DisabledAutoBurn();
    }

    /**
     * @dev Disables the reward feature.
     *
     * Emits a {DisabledReward} event.
     *
     * Requirements:
     *
     * - reward feature mush be enabled.
     */
    function disableReward() public onlyOwner {
        require(_rewardEnabled, "Reward is already disabled.");

        setTaxReward(0);
        _rewardEnabled = false;

        emit DisabledReward();
    }

    /**
     * @dev Disables the auto swap and liquify feature.
     *
     * Emits a {DisabledAutoSwapAndLiquify} event.
     *
     * Requirements:
     *
     * - auto swap and liquify feature mush be enabled.
     */
    function disableAutoSwapAndLiquify() public onlyOwner {
        require(
            _autoSwapAndLiquifyEnabled,
            "Auto swap and liquify  is already disabled."
        );

        setTaxLiquify(0);
        _autoSwapAndLiquifyEnabled = false;

        emit DisabledAutoSwapAndLiquify();
    }

    /**
     * @dev Updates `_minTokensBeforeSwap`
     *
     * Emits a {MinTokensBeforeSwap} event.
     *
     * Requirements:
     *
     * - `minTokensBeforeSwap_` must be less than _currentSupply.
     */
    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_)
        public
        onlyOwner
    {
        require(
            minTokensBeforeSwap_ < _currentSupply,
            "minTokensBeforeSwap must be higher than current supply."
        );

        uint256 previous = _minTokensBeforeSwap;
        _minTokensBeforeSwap = minTokensBeforeSwap_;

        emit MinTokensBeforeSwapUpdated(previous, _minTokensBeforeSwap);
    }

    function setTaxBurn(uint8 taxBurn_) public onlyOwner {
        require(
            _autoBurnEnabled,
            "Auto burn feature must be enabled."
        );
        require(taxBurn_ + _taxReward + _taxLiquify < 100, "Tax fee too high.");

        uint8 previousTax = _taxBurn;
        _taxBurn = taxBurn_;

        emit TaxBurnUpdate(previousTax, taxBurn_);
    }

    function setTaxReward(uint8 taxReward_) public onlyOwner {
        require(
            _rewardEnabled,
            "Reward feature must be enabled."
        );
        require(_taxBurn + taxReward_ + _taxLiquify < 100, "Tax fee too high.");

        uint8 previousTax = _taxReward;
        _taxReward = taxReward_;

        emit TaxRewardUpdate(previousTax, taxReward_);
    }

    function setTaxLiquify(uint8 taxLiquify_) public onlyOwner {
        require(
            _autoSwapAndLiquifyEnabled,
            "Auto swap and liquify feature must be enabled."
        );
        require(_taxBurn + _taxReward + taxLiquify_ < 100, "Tax fee too high.");

        uint8 previousTax = _taxLiquify;
        _taxLiquify = taxLiquify_;

        emit TaxLiquifyUpdate(previousTax, taxLiquify_);
    }
}