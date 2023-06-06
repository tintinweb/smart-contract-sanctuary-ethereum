/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.20;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
    constructor() {
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

   
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


abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

   
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

   
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

contract TaleofZuzu is ERC20, Ownable, Pausable {

    // variables
    
    uint256 private initialSupply;
   
    uint256 private denominator = 100;

    uint256 private swapThreshold = 0.0000009 ether; // The contract will only swap to ETH, once the fee tokens reach the specified threshold
    
    uint256 private devTaxBuy;
    uint256 private liquidityTaxBuy;
   
    
    uint256 private devTaxSell;
    uint256 private liquidityTaxSell;
    uint256 public maxWallet;
    
    address private devTaxWallet;
    address private liquidityTaxWallet;
    
    
    // Mappings
    
   
    mapping (address => bool) private excludeList;
   
    
    mapping (string => uint256) private buyTaxes;
    mapping (string => uint256) private sellTaxes;
    mapping (string => address) private taxWallets;
    
    bool public taxStatus = true;
    
    IUniswapV2Router02 private uniswapV2Router02;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Pair private uniswapV2Pair;
    
    constructor(string memory _tokenName,string memory _tokenSymbol,uint256 _supply) ERC20(_tokenName, _tokenSymbol) payable
    {
        initialSupply =_supply * (10**18);
        maxWallet = initialSupply * 2 / 100; 
        _setOwner(msg.sender);
        uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router02.factory());
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH()));
        taxWallets["liquidity"] = address(0);
        setBuyTax(1,20); //dev tax, liquidity tax
        setSellTax(1,20); //dev tax, liquidity tax
        setTaxWallets(0x86E74f125eAa9d9BaE39e7C2e9ea9d72522f86b2); 
        exclude(msg.sender);
        exclude(address(this));
        exclude(devTaxWallet);
        _mint(msg.sender, initialSupply);
    }
    
    
    uint256 private devTokens;
    uint256 private liquidityTokens;
    
    
    
    function handleTax(address from, address to, uint256 amount) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WETH();
        
        if(!isExcluded(from) && !isExcluded(to)) {
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            if(from == address(uniswapV2Pair)) {
                tax += baseUnit * buyTaxes["dev"];
                tax += baseUnit * buyTaxes["liquidity"];
               
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                
                devTokens += baseUnit * buyTaxes["dev"];
                liquidityTokens += baseUnit * buyTaxes["liquidity"];

            } else if(to == address(uniswapV2Pair)) {
                
                tax += baseUnit * sellTaxes["dev"];
                tax += baseUnit * sellTaxes["liquidity"];
                
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
               
                devTokens += baseUnit * sellTaxes["dev"];
                liquidityTokens += baseUnit * sellTaxes["liquidity"];
                
                
                uint256 taxSum =  devTokens + liquidityTokens;
                
                if(taxSum == 0) return amount;
                
                uint256 ethValue = uniswapV2Router02.getAmountsOut( devTokens + liquidityTokens, sellPath)[1];
                
                if(ethValue >= swapThreshold) {
                    uint256 startBalance = address(this).balance;

                    uint256 toSell = devTokens + liquidityTokens / 2 ;
                    
                    _approve(address(this), address(uniswapV2Router02), toSell);
            
                    uniswapV2Router02.swapExactTokensForETH(
                        toSell,
                        0,
                        sellPath,
                        address(this),
                        block.timestamp
                    );
                    
                    uint256 ethGained = address(this).balance - startBalance;
                    
                    uint256 liquidityToken = liquidityTokens / 2;
                    uint256 liquidityETH = (ethGained * ((liquidityTokens / 2 * 10**18) / taxSum)) / 10**18;
                    
                    
                    uint256 devETH = (ethGained * ((devTokens * 10**18) / taxSum)) / 10**18;
                   
                    
                    _approve(address(this), address(uniswapV2Router02), liquidityToken);
                    
                    uniswapV2Router02.addLiquidityETH{value: liquidityETH}(
                        address(this),
                        liquidityToken,
                        0,
                        0,
                        taxWallets["liquidity"],
                        block.timestamp
                    );
                    
                    uint256 remainingTokens = (devTokens + liquidityTokens) - (toSell + liquidityToken);
                    
                    if(remainingTokens > 0) {
                        _transfer(address(this), taxWallets["dev"], remainingTokens);
                    }
                    
                    
                   (bool success,) = taxWallets["dev"].call{value: devETH}("");
                   require(success, "transfer to  dev wallet failed");
                    
                    
                    if(ethGained - ( devETH + liquidityETH) > 0) {
                       (bool success1,) = taxWallets["dev"].call{value: ethGained - (devETH + liquidityETH)}("");
                        require(success1, "transfer to  dev wallet failed");
                    }

                    
                    
                    
                    devTokens = 0;
                    liquidityTokens = 0;
                    
                }
                
            }
            
            amount -= tax;
            if (to != address(uniswapV2Pair)){
                require(balanceOf(to) + amount <= maxWallet, "maxWallet limit exceeded");
            }
           
        }
        
        return amount;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        require(!paused(), "ERC20: token transfer while paused");
     
        
        if(taxStatus) {
            amount = handleTax(sender, recipient, amount);   
        }

        super._transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Triggers the tax handling functionality
     */
    function triggerTax() public onlyOwner {
        handleTax(address(0), address(uniswapV2Pair), 0);
    }
    
    /**
     * @dev Pauses transfers on the token.
     */
    function pause() public onlyOwner {
        require(!paused(), "ERC20: Contract is already paused");
        _pause();
    }

    /**
     * @dev Unpauses transfers on the token.
     */
    function unpause() public onlyOwner {
        require(paused(), "ERC20: Contract is not paused");
        _unpause();
    }

     /**
     * @dev set max wallet limit per address.
     */

    function setMaxWallet (uint256 amount) external onlyOwner {
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
     * @dev Sets tax for buys.
     */
    function setBuyTax(uint256 dev,uint256 liquidity) public onlyOwner {
        buyTaxes["dev"] = dev;
        buyTaxes["liquidity"] = liquidity;
       
    }
    
    /**
     * @dev Sets tax for sells.
     */
    function setSellTax(uint256 dev, uint256 liquidity) public onlyOwner {

        sellTaxes["dev"] = dev;
        sellTaxes["liquidity"] = liquidity;
        
    }
    
    /**
     * @dev Sets wallets for taxes.
     */
    function setTaxWallets(address dev) public onlyOwner {
        taxWallets["dev"] = dev;
        
    }

    function claimStuckTokens(address _token) external onlyOwner {
 
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
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
    
 
    
    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isExcluded(address account) public view returns (bool) {
        return excludeList[account];
    }
    
    receive() external payable {}
}