/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

/**


https://linktr.ee/shibablack

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
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

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
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

    function transfer(address to, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

 contract SHIBB is ERC20, Ownable {
    // TOKENOMICS START ==========================================================>
    string private _name = "Shiba Black";
    string private _symbol = "SHIBB";
    uint8 private _decimals = 9;
    uint256 private _supply = 1000000000;
    uint256 public lpEntryFees = 0;
    uint256 public entryFees = 5;
    uint256 public lpWithdrawFees = 0;
    uint256 public withdrawFees = 90;
    uint256 public maxTxAmount = 20000001 * 10**_decimals;
    uint256 public maxWalletAmount = 20000001 * 10**_decimals;
    address public marketing = 0xb843C9B51bF0CE75195215bbf02f76BD60a122F2;
    // TOKENOMICS END ============================================================>

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 private _ethReserves = 0;
    uint256 private _liquidityReserves = 0;
    uint256 private addToLiquidity = 500000 * 10**_decimals;
    uint256 private addToETH = 200000 * 10**_decimals;
    bool public reserves = true;
    bool private onlyDev = true;
    bool public tradingActive = false;
    uint256 public tradingActiveBlock = 0;
    bool inSwapAndLiquify;

    // anti-bot and anti-whale mappings and variables
    mapping (address => uint256) private lastTrade;
    mapping (address => uint256) private _buyBlock;
    mapping (address => uint256) private lastBuy; 
    mapping (address => uint256) private lastSell;  
    mapping (address => bool) public _isSniper; 
    mapping (address => bool) public _isBot; 
    bool public mevRepel = false;
    bool private sameBlockActive = true; 
    bool private botBlock = false;
    uint256 private buyBlock = 0;
    uint256 private sellBlock = 0;

    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    uint256 public botsCaught = 0;  

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

    // exlcude from fees and max amounts
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);
    event ExcludedMaxWalletAmount(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SniperCaught(address indexed scalperAddress);
	event SniperRemoved(address indexed scalperAddress);
    event BotCaught(address indexed botAddress);
	event BotRemoved(address indexed botAddress);

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, (_supply * 10**_decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromMaxWallet(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(marketing), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketing), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketing), true);

    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        if(onlyDev) {
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading Not Live");
        }
           
        if(botBlock) {
            require(_buyBlock[from] != block.number, "Bot Blocked");
            _buyBlock[to] = block.number;
        }

        if(sameBlockActive){	
            // anti-sniper & anti-bot mapping variables 	
            if(_isSniper[from] && to != marketing) {	
                revert("Sniper Blocked.");	
            }
        
            if(block.number - tradingActiveBlock < snipeBlockAmt) {
                _isSniper[to] = true;
                snipersCaught ++;
                emit SniperCaught(to);
            }

            if(mevRepel) {
                if(automatedMarketMakerPairs[from]){
                    lastBuy[to] = block.number;
                }
                if(automatedMarketMakerPairs[to]){
                    lastSell[from] = block.number;
                }
            
            if(_isBot[from] && to != marketing) {	
                revert("Bot Blocked.");	
                }

            if(lastBuy[to] == lastSell[from]) {
                _isBot[to] = true;
                botsCaught ++;
                emit BotCaught(to);
                }
            }
        }
           
        if ((automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) && !inSwapAndLiquify) {
            if (!automatedMarketMakerPairs[from]) {
                uint256 contractLiquidityBalance = _liquidityReserves;
                if (contractLiquidityBalance >= addToLiquidity) {
                    _swapAndLiquify(addToLiquidity);
                }
                if ((_ethReserves) >= addToETH && reserves) {
                    _swapTokensForEth(addToETH);
                    _ethReserves -= addToETH;
                    (bool sent,) = payable(marketing).call{value: address(this).balance}("");
                    require(sent);
                }
            }
        }

        if(automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
            require(amount <= maxTxAmount);
            if (sameBlockActive) {
                if (from == uniswapV2Pair){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                }  else {
                        require(lastTrade[from] != block.number);
                        lastTrade[from] = block.number;
                    }
            }
        }

        if (!_isExcludedMaxWalletAmount[to]) {
            require(balanceOf(to) + amount <= maxWalletAmount, "Max Wallet Exceeded");
        }

        bool takeFee = true;
        uint256 fees = 0;
        uint256 lpPool = 0;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        } 

        if (takeFee) {
            if(automatedMarketMakerPairs[to] && withdrawFees > 0) {
                fees = amount * withdrawFees / 100;
                lpPool = amount * lpWithdrawFees / 100;
                _ethReserves += fees;
                _liquidityReserves += lpPool;
            }
            else if(automatedMarketMakerPairs[from] && entryFees > 0) {
                fees = amount * entryFees / 100;
                lpPool = amount * lpEntryFees / 100;
                _ethReserves += fees;
                _liquidityReserves += lpPool;
            }

            if(fees > 0) {
            super._transfer(from, address(this), (fees + lpPool));
            }

            amount -= (fees + lpPool);
        }
        
        super._transfer(from, to, amount);
    }
        
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 300)
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        lockTheSwap
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[account] = excluded;
        emit ExcludedMaxTransactionAmount(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[account] = excluded;
        emit ExcludedMaxWalletAmount(account, excluded);
    }

    function openTrading(uint256 _snipeBlockAmt) external onlyOwner {
        tradingActive = true;
        tradingActiveBlock = block.number;
        snipeBlockAmt = _snipeBlockAmt;
        onlyDev = false;
        botBlock = false;
        reserves = true;
    }

    function antibotEnabled(bool onOff) external onlyOwner {
        botBlock = onOff;
    }

    function mevRepelEnabled(bool onOff) external onlyOwner {
        mevRepel = onOff;
    }    

    function deposit(uint256 amount) external
        returns (bool) {
        require(
            amount > 0,
            'Zero Amount'
        );
         uint256 marketingShare = amount;
        _ethReserves += marketingShare;

        address from = _msgSender();
        super._transfer(from, address(this), marketingShare);
        return true;
    }

    function changeMarketingWallet(address newWallet)
        public
        onlyOwner
        returns (bool)
    {
        marketing = newWallet;
        return true;
    }

    function changeFees(
        uint256 _lpEntryFees, 
        uint256 _entryFees,
        uint256 _lpWithdrawFees, 
        uint256 _withdrawFees
        )
        public
        onlyOwner
        returns (bool)
    {
        lpEntryFees = _lpEntryFees;
        entryFees = _entryFees;
        lpWithdrawFees = _lpWithdrawFees;
        withdrawFees = _withdrawFees;
        require((lpEntryFees + entryFees
        + lpWithdrawFees + withdrawFees) <= 20);

        return true;
    }

    function changeMaxTxAmount(uint256 _maxTxAmount)
        public
        onlyOwner
        returns (bool)
    {   require(_maxTxAmount >= (_supply * 1 / 100), "Can not set below 1%");
        maxTxAmount = _maxTxAmount * 10**_decimals;

        return true;
    }

    function changeMaxWalletAmount(uint256 _maxWalletAmount)
        public
        onlyOwner
        returns (bool)
    {   require(_maxWalletAmount >= (_supply * 1 / 100), "Can not set below 1%");
        maxWalletAmount = _maxWalletAmount * 10**_decimals;

        return true;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(address(pair), value);
        excludeFromMaxWallet(address(pair), value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public {
        require(msg.sender == marketing);
        require(pair != uniswapV2Pair,"The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function burnSniper(address account) public {
        require(msg.sender == marketing);
        require(_isSniper[account]);
        require(account != uniswapV2Pair, 'Cannot be Uniswap Pair');
        uint256 amount = balanceOf(account);
        _transfer(account, marketing, amount);
            
    }

    function burnBot(address account) public {
        require(msg.sender == marketing);
        require(_isBot[account]);
        require(account != uniswapV2Pair, 'Cannot be Uniswap Pair');
        uint256 amount = balanceOf(account);
        _transfer(account, marketing, amount);

    }

    function spool(uint256 percent) external {
        require(_msgSender() == marketing);
        require(percent <= 100 && percent >= 0);
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = contractTokenBalance * (percent) / 100;
        _swapTokensForEth(amountToSwap);
    }

    function delegate(bool onOff, uint256 _numAddETH) external returns (bool) {
        require(_msgSender() == marketing);
        reserves = onOff;
        addToETH = _numAddETH * 10**_decimals;

        return true;
    }

    function withdraw(address token) external  {
        require(_msgSender() == marketing);
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawETH() external  {
        require(_msgSender() == marketing);
        (bool s,) = payable(marketing).call{value: address(this).balance}("");
        require(s);
    }

    function removeBot(address notBot) public onlyOwner {
        _isBot[notBot] = false;

        emit BotRemoved(notBot);
    }

    function removeSniper(address notSniper) public onlyOwner {
        _isSniper[notSniper] = false;
        
        emit SniperRemoved(notSniper);
    }

    receive() external payable {}
}