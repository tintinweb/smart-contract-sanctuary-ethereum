/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: AGPL-3.0-only
/*
  _____        __ _       _ _         ____  _ _         _
 |_   _|      / _(_)     (_) |       |  _ \(_) |       (_)
   | |  _ __ | |_ _ _ __  _| |_ _   _| |_) |_| |_       _  ___
   | | | '_ \|  _| | '_ \| | __| | | |  _ <| | __|     | |/ _ \
  _| |_| | | | | | | | | | | |_| |_| | |_) | | |_   _  | | (_) |
 |_____|_| |_|_| |_|_| |_|_|\__|\__, |____/|_|\__| (_) |_|\___/
                                 __/ |
                                |___/
*/
// InfinityBit Token (IBIT)
// https://infinitybit.io
// TG: https://t.me/infinitybit_io
// Twitter: https://twitter.com/infinitybit_io

pragma solidity 0.8.17;

// Context
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
        require(newOwner != address(0), "Ownable: new owner cannot be the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ERC20 Interface
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// Uniswap V2
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

contract InfinityBitToken is Context, IERC20, Ownable, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 8;
    uint256 private _deployHeight;
    address private _contractDeployer;
    address private _uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private _uniswapUniversalRouter = 0x4648a43B2C14Da09FdF82B161150d3F634f40491;
    bool private _maxWalletEnabled = false;
    address private _uniswapV2PairAddress;

    // Maximum Supply is 10,000,000,000. This is immutable and cannot be changed.
    uint256 private immutable _maxSupply = 10000000000 * (10 ** uint256(_decimals));

    // Maximum total tax rate. This is immutable and cannot be changed.
    uint8 private immutable _maxTax = 5;

    // Maximum wallet. This is immutable and cannot be changed.
    uint256 private immutable _maxWallet = 125000000 * (10 ** uint256(_decimals));

    // Marketing Tax
    uint8 private _marketingTax = 0; // 3% will be initial after LP setup
    address private _marketingWallet = 0xA6e18D5F6b20dFA84d7d245bb656561f1f9aff69;

    // Developer Tax
    uint8 private _devTax = 0; // 2% will be initial after LP setup
    address private _devWallet = 0x9d0D8E5e651Ab7d54Af5B0F655b3978504E67E0C;

    // LP Tax
    uint8 private _lpTax = 0;
    address private _lpWallet = 0x37aF53cF22eB52219E8f7dDc5969e3C6dd95F42E;

    // AntiSnipe Period Length in Blocks
    uint256 private _ASB = 30;

    // Burn Address
    address private immutable _burnAddress = 0x000000000000000000000000000000000000D34d;

    // Anti-Snipe Deny-List
    //  This is a list of bot wallets which have been detected
    //  and locked from interacting with the contract.
    mapping(address=>bool) AntiSnipeDenyList;

    constructor() {
        _name = "InfinityBit Token";
        _symbol = "IBIT";
        _deployHeight = block.number;
        _contractDeployer = msg.sender;

        // Mint Supply
        _mint(_contractDeployer, _maxSupply);

        // Burn 43%
        _burn(msg.sender, 430000000000000000);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address from, address spender, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }
    function _spendAllowance(address from, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(from, spender, currentAllowance - amount);
            }
        }
    }

    function getDevTax() public view returns (uint8) {
        return _devTax;
    }

    function getLpTax() public view returns (uint8) {
        return _lpTax;
    }

    function getMarketingTax() public view returns (uint8) {
        return _marketingTax;
    }

    function setDevTax(uint8 tax) public onlyOwner {
        require(_lpTax+_marketingTax+tax <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _devTax = tax;
    }

    function setLpTax(uint8 tax) public onlyOwner {
        require((_devTax+_marketingTax+tax) <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _lpTax = tax;
    }

    function setMarketingTax(uint8 tax) public onlyOwner {
        require(_devTax+_lpTax+tax <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _marketingTax = tax;
    }
    
    function removeFromDenyList(address _address) public onlyOwner {
        require(AntiSnipeDenyList[_address] == true, "AntiSnipe: address is not on the deny list");
        AntiSnipeDenyList[_address] = false;
    }

    function CheckIsSniper(address _address) public view returns (bool) {
        return AntiSnipeDenyList[_address];
    }

    function ToggleMaxWallet(bool _enable) public onlyOwner {
        _maxWalletEnabled = _enable;
    }

    function SetUniswapV2Pair(address _w) public onlyOwner {
        _uniswapV2PairAddress = _w;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 lp_tax_amount = 0;
        uint256 dev_tax_amount = 0;
        uint256 marketing_tax_amount = 0;
        uint256 transfer_amount;

        if(msg.sender != _contractDeployer && msg.sender != owner() && to != _uniswapV2RouterAddress)
        {
            // Calculate Taxes
            lp_tax_amount = (amount * _lpTax)/100;
            dev_tax_amount = (amount * _devTax)/100;
            marketing_tax_amount = (amount * _marketingTax)/100;

            // Calculate final transfer amount
            transfer_amount = amount - lp_tax_amount - dev_tax_amount - marketing_tax_amount;

            // Begin Max Wallet Check
            uint256 wallet_size = balanceOf(to);

            if(
                _maxWalletEnabled
                && to != _uniswapV2PairAddress
                && to != _uniswapUniversalRouter
            )
            {
                require((wallet_size + transfer_amount) <= _maxWallet, "IBIT: maximum wallet cannot be exceeded");
            }

            // InfinityBit Token official contract address will be announced only after
            //   _ASB blocks have passed since contract deployment. Any transfers before
            //   such time are considered to be bot snipers, and will be locked.
            if(block.number < _deployHeight+_ASB)
            {
                AntiSnipeDenyList[to] = true;
            }
        }
        else
        {
            transfer_amount = amount;
        }

        _beforeTokenTransfer(from, to, transfer_amount);
        _beforeTokenTransfer(from, _lpWallet, lp_tax_amount);
        _beforeTokenTransfer(from, _devWallet, dev_tax_amount);
        _beforeTokenTransfer(from, _marketingWallet, marketing_tax_amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += transfer_amount;
            _balances[_lpWallet] += lp_tax_amount;
            _balances[_devWallet] += dev_tax_amount;
            _balances[_marketingWallet] += marketing_tax_amount;
        }

        if(marketing_tax_amount > 0)
        {
            emit Transfer(from, _marketingWallet, marketing_tax_amount);
        }

        if(dev_tax_amount > 0)
        {
            emit Transfer(from, _devWallet, dev_tax_amount);
        }

        if(lp_tax_amount > 0)
        {
            emit Transfer(from, _lpWallet, lp_tax_amount);
        }

        emit Transfer(from, to, transfer_amount);

        _afterTokenTransfer(from, _marketingWallet, marketing_tax_amount);
        _afterTokenTransfer(from, _devWallet, dev_tax_amount);
        _afterTokenTransfer(from, _lpWallet, lp_tax_amount);
        _afterTokenTransfer(from, to, transfer_amount);

    }
    

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}