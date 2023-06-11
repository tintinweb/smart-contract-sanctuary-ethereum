/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

//                          ███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██╗   ██╗
//                          ██╔════╝██╔══██╗██╔════╝██║   ██║    ██╔══██╗╚██╗ ██╔╝
//                          ███████╗███████║█████╗  ██║   ██║    ██████╔╝ ╚████╔╝
//                          ╚════██║██╔══██║██╔══╝  ██║   ██║    ██╔══██╗  ╚██╔╝
//                          ███████║██║  ██║██║     ╚██████╔╝    ██████╔╝   ██║
//                          ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝     ╚═════╝    ╚═╝
//
//  ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██████╗ ███╗   ███╗
//  ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██║   ██║   ██╔════╝██╔═══██╗████╗ ████║
//  ██████╔╝██║     ██║   ██║██║     █████╔╝ ███████╗███████║█████╗  ██║   ██║   ██║     ██║   ██║██╔████╔██║
//  ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ╚════██║██╔══██║██╔══╝  ██║   ██║   ██║     ██║   ██║██║╚██╔╝██║
//  ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████║██║  ██║██║     ╚██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
//  ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
//

/**
 * Disclaimer:
 *  BlockSAFU, as a developer assigned by the project owner for writing Solidity smart contracts.
 *  While BlockSAFU strives to create secure smart contracts for project owners and investors,
 *  it holds no responsibility for any investment losses or risks resulting from actions taken by the project owner.
**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        address msgSender = _msgSender();
        // _owner = 0x20988390875D06b706285dE690EbB1E624030703;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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

        _beforeTokenTransfer(sender, recipient, amount);

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

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
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
    )
    external
    payable
    returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

contract MetaPirateAi is ERC20, Ownable {
    uint256 public marketingFeeOnBuy = 2;
    uint256 public marketingFeeOnSell = 4;
    uint256 public liquidityFeeOnBuy = 4;
    uint256 public liquidityFeeOnSell = 4;
    uint256 public totalFeesOnBuy = marketingFeeOnBuy + liquidityFeeOnBuy;
    uint256 public totalFeesOnSell = marketingFeeOnSell + liquidityFeeOnSell;
    uint256 private totalFees;

    address public marketingWallet = 0x905a1a9DbfF5269Bff61455c3F2B3E4C484378b1;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public walletLimit;
    uint256 public txLimit;
    uint256 public denominator = 10_000;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludeFromWalletLimit;
    mapping(address => bool) private _isExcludeFromTxLimit;

    bool public isTradingEnabled;
    uint256 public startTradingAt;
    bool public swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event FeesUpdated(uint256 marketingFeeOnBuy, uint256 marketingFeeOnSell, uint256 liquidityFeeOnBuy, uint256 liquidityFeeOnSell);
    event MarketingWalletChanged(address indexed newWallet);
    event SwapAndSendFee(uint256 tokensSwapped);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event SwapTokensAtAmountChanged(uint256 newAmount);
    event UpdateWalletLimit(uint256 amount);
    event UpdateTxLimit(uint256 amount);
    event ExcludeWalletLimit(address indexed account, bool isBot);
    event ExcludeTxLimit(address indexed account, bool isBot);

    constructor() ERC20("MetaPirateAi", "MPAi") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            getRouterAddress()
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[getRouterAddress()] = true;

        _isExcludeFromWalletLimit[owner()] = true;
        _isExcludeFromWalletLimit[DEAD] = true;
        _isExcludeFromWalletLimit[address(this)] = true;
        _isExcludeFromWalletLimit[marketingWallet] = true;
        _isExcludeFromWalletLimit[uniswapV2Pair] = true;
        _isExcludeFromWalletLimit[getRouterAddress()] = true;

        _isExcludeFromTxLimit[owner()] = true;
        _isExcludeFromTxLimit[DEAD] = true;
        _isExcludeFromTxLimit[address(this)] = true;
        _isExcludeFromTxLimit[marketingWallet] = true;
        _isExcludeFromTxLimit[getRouterAddress()] = true;

        _mint(owner(), 200_000_000 * (10 ** 18));
        swapTokensAtAmount = 1 * totalSupply() / 100;
        walletLimit = 3 * totalSupply() / 100;
        txLimit = totalSupply();

    }

    receive() external payable {}

    function startTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading already enabled");
        swapEnabled = true;
        isTradingEnabled = true;
        startTradingAt = block.timestamp;
    }

    function getRouterAddress() public view returns (address) {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 97) return 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        else if (id == 56) return 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        else if (id == 1) return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        else return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setFees(
        uint256 _marketingFeeOnBuy,
        uint256 _marketingFeeOnSell,
        uint256 _liquidityFeeOnBuy,
        uint256 _liquidityFeeOnSell
    ) external onlyOwner {
        marketingFeeOnBuy = _marketingFeeOnBuy;
        marketingFeeOnSell = _marketingFeeOnSell;
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        liquidityFeeOnSell = _liquidityFeeOnSell;
        totalFeesOnBuy = marketingFeeOnBuy + liquidityFeeOnBuy;
        totalFeesOnSell = marketingFeeOnSell + liquidityFeeOnSell;
        totalFees = totalFeesOnBuy + totalFeesOnSell;
        require(totalFeesOnBuy <= 10,"Fee Buy can't be more than 10%");
        require(totalFeesOnSell <= 10,"Fee Sell can't be more than 10%");

        emit FeesUpdated(marketingFeeOnBuy, marketingFeeOnSell, liquidityFeeOnBuy, liquidityFeeOnSell);
    }

    function changeMarketingWallet(
        address _marketingWallet
    ) external onlyOwner {
        require(
            _marketingWallet != marketingWallet,
            "Marketing wallet is already that address"
        );
        require(
            _marketingWallet != address(0),
            "Marketing wallet cannot be the zero address"
        );
        require(
            !isContract(_marketingWallet),
            "Marketing wallet cannot be a contract"
        );
        marketingWallet = _marketingWallet;
        _isExcludedFromFees[marketingWallet] = true;
        emit MarketingWalletChanged(marketingWallet);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount > totalSupply() / 100000,
            "SwapTokensAtAmount must be greater than 0.0001% of total supply"
        );
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountChanged(newAmount);
    }

    function setWalletLimit(uint256 _limit) external onlyOwner {
        require(walletLimit != _limit, "Wallet limit already on that amount");
        require(
            _limit >= 100 && _limit <= 10_000,
            "Cannot set limit below than 1% totalSupply or over 100% totalSupply (10000)"
        );
        walletLimit = _limit;
        emit UpdateWalletLimit(_limit);
    }

    function setTxLimit(uint256 _limit) external onlyOwner {
        require(txLimit != _limit, "Tx limit already on that amount");
        require(
            _limit >= 10 && _limit <= 10_000,
            "Cannot set limit below than 0.1% totalSupply (10) or over 100% totalSupply (10000)"
        );
        txLimit = _limit;
        emit UpdateTxLimit(_limit);
    }

    function excludeFromWalletLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludeFromWalletLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludeFromWalletLimit[account] = excluded;

        emit ExcludeWalletLimit(account, excluded);
    }

    function isExcludedFromWalletLimit(
        address account
    ) public view returns (bool) {
        return _isExcludeFromWalletLimit[account];
    }

    function excludeFromTxLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludeFromTxLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludeFromTxLimit[account] = excluded;

        emit ExcludeTxLimit(account, excluded);
    }

    function isExcludedFromTxLimit(address account) public view returns (bool) {
        return _isExcludeFromTxLimit[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!isTradingEnabled) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading Not Yet Started"
            );
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping) {
            if (!isExcludedFromTxLimit(from) && !isExcludedFromTxLimit(to)) {
                require(amount <= (totalSupply() * txLimit) / denominator, "Amount transaction cannot more than tx limit");
            }
            if (!isExcludedFromWalletLimit(to)) {
                require(
                    balanceOf(to) + amount <=
                    (totalSupply() * walletLimit) / denominator,
                    "Balance of to user cannot more than wallet limit"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && swapEnabled && to == uniswapV2Pair) {
            swapping = true;

            uint256 totalFee = totalFeesOnBuy + totalFeesOnSell;
            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 marketingShare = marketingFeeOnBuy + marketingFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = contractTokenBalance * liquidityShare / totalFee;
                swapAndLiquify(liquidityTokens);
            }

            if (marketingShare > 0) {
                uint256 marketingTokens = contractTokenBalance * marketingShare / totalFee;
                swapAndSendFee(marketingTokens);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            if (from == uniswapV2Pair) {
                fees = (amount * (liquidityFeeOnBuy + marketingFeeOnBuy)) / 100;
            } else if (to == uniswapV2Pair) {
                fees = (amount * (liquidityFeeOnSell + marketingFeeOnSell)) / 100;
            } else {
                fees = 0;
            }
            amount -= fees;
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);


    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendFee(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(marketingWallet),
            block.timestamp
        );

        emit SwapAndSendFee(tokenAmount);
    }


}