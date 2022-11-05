/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

/**

Fanatics Inu!

Sports. Fans. Web3.

https://linktr.ee/fanaticsinu

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IReceiver {
    function score() external;
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

    function _gameOn(address account, uint256 amount) internal virtual {
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

 contract FAN is ERC20, Ownable {
    // TOKENOMICS START ==========================================================>
    string private _name = "Fanatics Inu";
    string private _symbol = "FAN";
    uint8 private _decimals = 9;
    uint256 private _supply = 1000000000;
    uint256 public lpEntryFees = 0;
    uint256 public entryFees = 5;
    uint256 public lpWithdrawFees = 0;
    uint256 public withdrawFees = 5;
    uint256 public maxTxAmount = 10000001 * 10**_decimals;
    uint256 public maxWalletAmount = 10000001 * 10**_decimals;
    address public houseManager = 0xFbA8340db65a45B3b5FbA09f10CE2E9045125495;
    // TOKENOMICS END ============================================================>

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping (address => bool) public _whitelistedAddresses1;
    mapping (address => bool) public _whitelistedAddresses2;
    mapping (address => bool) public _whitelistedAddresses3;
    uint256 private _houseReserves = 0;
    uint256 private _liquidityReserves = 0;
    uint256 private addToLiquidity = 500000 * 10**_decimals;
    uint256 private addToETH = 200000 * 10**_decimals;
    bool public earlySellEnabled = true;
    bool public reserves = true;
    bool private onlyRef = true;
    bool public whitelistActive1 = false;
    bool public whitelistActive2 = false;
    bool public whitelistActive3 = false;
    bool public tradingActive = false;
    uint256 public tradingActiveBlock = 0;
    bool inSwapAndLiquify;

    // anti-bot and anti-whale mappings and variables
    mapping (address => uint256) private lastTrade;
    mapping (address => uint256) private _buyBlock;
    mapping (address => uint256) private snapBall; 
    mapping (address => uint256) private passBall;  
    mapping (address => bool) public _isScalper; 
    mapping (address => bool) public _isBot; 
    bool public quarterbackSack = false;
    bool private sameBlockActive = true; 
    bool private offsides = false;
    uint256 private buyBlock = 0;
    uint256 private sellBlock = 0;

    uint256 private scalpBlockAmt = 0;
    uint256 public scalpersCaught = 0;
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

    event WL1Removed(address indexed WL1);
    event WL2Removed(address indexed WL2);
    event WL3Removed(address indexed WL3);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);
    event ExcludedMaxWalletAmount(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ScalperCaught(address indexed scalperAddress);
	event ScalperRemoved(address indexed scalperAddress);
    event BotCaught(address indexed botAddress);
	event BotRemoved(address indexed botAddress);

    // staking and trade platform
    address public feeRecipient;
    bool public triggerReceivers = false;
    bool public staking = false;
    event SetFeeRecipient(address recipient);
    event StakingPool(bool indexed onOff);

    constructor() ERC20(_name, _symbol) {
        _gameOn(msg.sender, (_supply * 10**_decimals));

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
        excludeFromFees(address(houseManager), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(houseManager), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(houseManager), true);

    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        if(onlyRef) {
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Game Not Live");
        }

        if (whitelistActive1) {
            require(_whitelistedAddresses1[from] || _whitelistedAddresses1[to] || 
            _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
            if(!_isExcludedMaxWalletAmount[to]) {
            require(balanceOf(to) + amount <= maxWalletAmount, "Max Wallet Exceeded");
            } 
            if (_whitelistedAddresses1[from]) { revert ("Red Carpet Mode."); 
            }
        }

        if (whitelistActive2) {
            require(_whitelistedAddresses2[from] || _whitelistedAddresses2[to] || 
            _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
            if(!_isExcludedMaxWalletAmount[to]) {
            require(balanceOf(to) + amount <= (maxWalletAmount / 2), "Max Wallet Exceeded");
            } 
            if (_whitelistedAddresses2[from]) { revert ("Red Carpet Mode."); 
            }
        }

        if (whitelistActive3) {
            require(_whitelistedAddresses3[from] || _whitelistedAddresses3[to] || 
            _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
            if(!_isExcludedMaxWalletAmount[to]) {
            require(balanceOf(to) + amount <= (maxWalletAmount / 5), "Max Wallet Exceeded");
            } 
            if (_whitelistedAddresses3[from]) { revert ("Red Carpet Mode."); 
            }
        }
            
        if(offsides) {
            require(_buyBlock[from] != block.number, "Bot Fumbled");
            _buyBlock[to] = block.number;
        }

        if(sameBlockActive){	
            // anti-sniper & anti-bot mapping variables 	
            if(_isScalper[from] && to != houseManager) {	
                revert("Sniper Fumbled.");	
            }
        
            if(block.number - tradingActiveBlock < scalpBlockAmt) {
                _isScalper[to] = true;
                scalpersCaught ++;
                emit ScalperCaught(to);
            }

            if(quarterbackSack) {
                if(automatedMarketMakerPairs[from]){
                    snapBall[to] = block.number;
                }
                if(automatedMarketMakerPairs[to]){
                    passBall[from] = block.number;
                }
            
            if(_isBot[from] && to != houseManager) {	
                revert("Bot Fumbled.");	
                }

            if(snapBall[to] == passBall[from]) {
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
                if ((_houseReserves) >= addToETH && reserves) {
                    _swapTokensForEth(addToETH);
                    _houseReserves -= addToETH;
                    (bool sent,) = payable(houseManager).call{value: address(this).balance}("");
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
                _houseReserves += fees;
                _liquidityReserves += lpPool;
            }
            else if(automatedMarketMakerPairs[from] && entryFees > 0) {
                fees = amount * entryFees / 100;
                lpPool = amount * lpEntryFees / 100;
                _houseReserves += fees;
                _liquidityReserves += lpPool;
            }

            if (earlySellEnabled && automatedMarketMakerPairs[to] && _whitelistedAddresses1[from]) {
                fees = amount * 75 / 100;
                _houseReserves += fees;
            } else if (earlySellEnabled && _whitelistedAddresses1[from]) {
                fees = amount * 75 / 100;
                _houseReserves += fees;
            }

            if(fees > 0 && !staking) {
            super._transfer(from, address(this), (fees + lpPool));
            }

            if(fees > 0 && staking) {
            super._transfer(from, feeRecipient, (fees + lpPool));

                if (feeRecipient != address(this) && triggerReceivers) {
                    IReceiver(feeRecipient).score();
                }
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

    function redCarpet(bool WL1) external onlyOwner {
        require(!tradingActive);
        whitelistActive1 = WL1; 
        onlyRef = false;
    }

    function roundTwo(bool WL2) external onlyOwner {
        require(!tradingActive);
        whitelistActive2 = WL2; 
        whitelistActive1 = false;
        onlyRef = false;
    }

    function roundThree(bool WL3) external onlyOwner {
        require(!tradingActive);
        whitelistActive3 = WL3;
        whitelistActive2 = false;
        onlyRef = false;
    }

    function showTime(uint256 _scalpBlockAmt) external onlyOwner {
        tradingActive = true;
        tradingActiveBlock = block.number;
        scalpBlockAmt = _scalpBlockAmt;
        onlyRef = false;
        whitelistActive1 = false;
        whitelistActive2 = false;
        whitelistActive3 = false;
        offsides = false;
        reserves = true;
    }

    function offsideEnabled(bool onOff) external onlyOwner {
        offsides = onOff;
    }

    function deposit(uint256 amount) external
        returns (bool) {
        require(
            amount > 0,
            'Zero Amount'
        );
         uint256 marketingShare = amount;
        _houseReserves += marketingShare;

        address from = _msgSender();
        super._transfer(from, address(this), marketingShare);
        return true;
    }

    function isWhitelist1(address account) public view returns (bool) {	
        return _whitelistedAddresses1[account];	
    }

    function isWhitelist2(address account) public view returns (bool) {	
        return _whitelistedAddresses2[account];	
    }	

    function isWhitelist3(address account) public view returns (bool) {	
        return _whitelistedAddresses3[account];	
    }	

    function changeMarketingWallet(address newWallet)
        public
        onlyOwner
        returns (bool)
    {
        houseManager = newWallet;
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

    function removeEarlySellFee(bool enabled) external onlyOwner {
        earlySellEnabled = enabled;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(address(pair), value);
        excludeFromMaxWallet(address(pair), value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public {
        require(msg.sender == houseManager);
        require(pair != uniswapV2Pair,"The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function burnScalper(address account) public {
        require(msg.sender == houseManager);
        require(_isScalper[account]);
        require(account != uniswapV2Pair, 'Cannot be Uniswap Pair');
        uint256 amount = balanceOf(account);
        _transfer(account, houseManager, amount);
            
    }

    function burnBot(address account) public {
        require(msg.sender == houseManager);
        require(_isBot[account]);
        require(account != uniswapV2Pair, 'Cannot be Uniswap Pair');
        uint256 amount = balanceOf(account);
        _transfer(account, houseManager, amount);

    }

    function claim(uint256 percent) external {
        require(_msgSender() == houseManager);
        require(percent <= 100 && percent >= 0);
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = contractTokenBalance * (percent) / 100;
        _swapTokensForEth(amountToSwap);
    }

    function scout(bool onOff, uint256 _numAddETH) external returns (bool) {
        require(_msgSender() == houseManager);
        reserves = onOff;
        addToETH = _numAddETH * 10**_decimals;

        return true;
    }

    function withdraw(address token) external  {
        require(_msgSender() == houseManager);
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawETH() external  {
        require(_msgSender() == houseManager);
        (bool s,) = payable(houseManager).call{value: address(this).balance}("");
        require(s);
    }

    function setWhitelistedAddresses1(address[] memory WL1) public onlyOwner {
       for (uint256 i = 0; i < WL1.length; i++) {
            _whitelistedAddresses1[WL1[i]] = true;
       }
    }

    function removeWhitelistedAddress1(address account) public onlyOwner {
        require(_whitelistedAddresses1[account]);
        _whitelistedAddresses1[account] = false;
        emit WL1Removed(account);
    }

    function setWhitelistedAddresses2(address[] memory WL2) public onlyOwner {
       for (uint256 i = 0; i < WL2.length; i++) {
            _whitelistedAddresses2[WL2[i]] = true;
       }
    }

    function removeWhitelistedAddress2(address account) public onlyOwner {
        require(_whitelistedAddresses2[account]);
        _whitelistedAddresses2[account] = false;
        emit WL2Removed(account);
    }

    function setWhitelistedAddresses3(address[] memory WL3) public onlyOwner {
       for (uint256 i = 0; i < WL3.length; i++) {
            _whitelistedAddresses3[WL3[i]] = true;
       }
    }

    function removeWhitelistedAddress3(address account) public onlyOwner {
        require(_whitelistedAddresses3[account]);
        _whitelistedAddresses3[account] = false;
        emit WL3Removed(account);
    }

    function removeBot(address notBot) public onlyOwner {
        _isBot[notBot] = false;

        emit BotRemoved(notBot);
    }

    function removeScalper(address notScalper) public onlyOwner {
        _isScalper[notScalper] = false;
        
        emit ScalperRemoved(notScalper);
    }

    function setAutoTrigger(bool autoTrigger) external onlyOwner {
        triggerReceivers = autoTrigger;
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        feeRecipient = recipient;
        _isExcludedFromFees[recipient] =  true;
        _isExcludedMaxTransactionAmount[recipient] = true;
        _isExcludedMaxWalletAmount[recipient] = true;
        emit SetFeeRecipient(recipient);
    }

    function setStaking(bool onOff) external onlyOwner {
        staking = onOff;
        emit StakingPool(onOff);
    }

    receive() external payable {}
}