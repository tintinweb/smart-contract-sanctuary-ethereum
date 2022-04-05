/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/
    /**
     * Welcome to my Secret Laboratory.
     *  
     * A Moon Weapon we shall create...
     * I will collect ethereum to buy and burn tokens so that we can build at a prestigious rate.
     * 
     * https://t.me/DexterPortal
     */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "[dexter][ownable] caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "[dexter][ownable] new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

abstract contract ERC20 is Context, IERC20, IERC20Metadata {
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


contract Dexter is Context, IERC20, Ownable{
    // lib
        using SafeMath for uint256;
        using Address for address;

    // interfaces
        IUniswapV2Router02 private _router;
        IUniswapV2Pair private _pair;
        ERC20 private ERC20_NATIVE;
        ERC20 private ERC20_USDC;

    // tokenomics
        string private _name = "Dexter";
        string private _symbol = "DEX";
        uint8 private _decimals = 9;
        uint256 private _totalSupply = 1000000000 * (10**9); // 1 billion total
        uint256 private _roundingPrecision = 10**18;

    // taxes
        uint256 public TAXES_MARKETING;
        uint256 public TAXES_DEVELOPER;
        uint256 public TAXES_BUYBACK;

        uint16 public TAX_BUY_MARKETING = 60; // 6% marketing
        uint16 public TAX_BUY_DEVELOPER = 40; // 4% developer and development 
        uint16 public TAX_BUY_BUYBACK = 0;

        uint16 public TAX_SELL_MARKETING = 70; // 7% marketing
        uint16 public TAX_SELL_DEVELOPER = 60; // 6% developer and development 
        uint16 public TAX_SELL_BUYBACK = 20; // 2% buyback for lp and burn

        uint16 public TAX24H_SELL_MARKETING = 150; // 15% buyback for lp and burn first 24hrs
        uint16 public TAX24H_SELL_DEVELOPER = 40; // 4% buyback for lp and burn first 24hrs 
        uint16 public TAX24H_SELL_BUYBACK = 10; // 1% buyback for lp and burn first 24hrs

    // limits
        uint16 public LIMIT_WALLET = 20; // 2% of total supply
        uint16 public LIMIT_TRANSACTION = 10; // 1% of total supply
        uint32 public LIMIT_MCAP = 25000; // limit release at 25k mc
        bool public LIMIT_ACTIVE;
        bool public LIMIT24H_ACTIVE;
        uint256 public LIMIT24H_END;

    // addresses
        address public ADDRESS_PAIR;
        address public ADDRESS_BURN = 0x000000000000000000000000000000000000dEaD; // burn wallet address 
        address public ADDRESS_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // address of the uniswap router
        address public ADDRESS_ERC20_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // address of the USDC coin on this blockchain
        address public ADDRESS_MARKETING = 0x1F65A73d65d866DA9c8e9C1d7Cd01F55D55AE48C; // marketing wallet addess
        address public ADDRESS_DEVELOPER = 0x8096C9C81f5ED850c105b248C9699EC336099BDE; // developer wallet address
        address public ADDRESS_BUYBACK = 0xDC76F15AC4Ce0c139Aa384c65892c0114Bf931f2; // buyback wallet address

    // storage
        struct IndividualTax{
            uint16 buyMarketing;
            uint16 buyDeveloper;
            uint16 buyBuyback;

            uint16 sellMarketing;
            uint16 sellDeveloper;
            uint16 sellBuyback;
        }
        bool private _tradingEnabled;
        bool private _liquidityProvided;
        bool private _swapping;
        mapping(address => uint256) private _balances; 
        mapping(address => mapping (address => uint256)) private _allowances;
        mapping(address => bool) private _addressNoTaxes;
        mapping(address => bool) private _addressNoLimits;
        mapping(address => bool) private _addressAuthorized;
        mapping(address => IndividualTax) private _addressIndividualTax;
        mapping(address => bool) private _addressIndividualTaxes;

    // paths
        // token to native
            address[] public PATH_TOKEN_NATIVE = new address[](2);

        struct Taxes{
            uint16 marketing;
            uint16 developer;
            uint16 buyback;

            uint256 totalMarketing;
            uint256 totalDeveloper;
            uint256 totalBuyback;
            uint256 total;

            bool buy;
            bool sell;
        }

    // modifiers
        modifier onlyAuthorized(){
            require(_addressAuthorized[_msgSender()], "[dexter] only authorized wallets can call this function!");
            _;
        }

        modifier onlySwapOnce(){
            _swapping = true;
            _;
            _swapping = false;
        }

    receive() external payable {}

    constructor(){
        // token creation and dinstribution
            _balances[address(this)] = _totalSupply;

        // set interfaces
            _router = IUniswapV2Router02(ADDRESS_ROUTER);
            ADDRESS_PAIR = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
            _pair = IUniswapV2Pair(ADDRESS_PAIR); 
             _approve(address(this), address(_router), 2**256 - 1);

            ERC20_NATIVE = ERC20(_router.WETH());
            ERC20_USDC = ERC20(ADDRESS_ERC20_USDC);

        // set no taxes
            _addressNoTaxes[address(this)] = true;
            _addressNoTaxes[ADDRESS_BURN] = true;
            _addressNoTaxes[ADDRESS_MARKETING] = true;
            _addressNoTaxes[ADDRESS_DEVELOPER] = true;
            _addressNoTaxes[ADDRESS_BUYBACK] = true;

        // set no limits
            _addressNoLimits[address(this)] = true;
            _addressNoLimits[ADDRESS_BURN] = true;
            _addressNoLimits[ADDRESS_MARKETING] = true;
            _addressNoLimits[ADDRESS_DEVELOPER] = true;
            _addressNoLimits[ADDRESS_BUYBACK] = true;

        // set authorization
            _addressAuthorized[_msgSender()] = true;
            _addressAuthorized[ADDRESS_MARKETING] = true;
            _addressAuthorized[ADDRESS_DEVELOPER] = true;
            _addressAuthorized[ADDRESS_BUYBACK] = true; 

        // path
            PATH_TOKEN_NATIVE[0] = address(this);
            PATH_TOKEN_NATIVE[1] = _router.WETH();           
    }



    // owner
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    function addLiquidity() public onlyAuthorized{
        require(!_liquidityProvided, "[dexter] liquidity can only be enabled once!");
        _addLiquidity();
    }

    function enableTrading() public onlyAuthorized{
        require(!_tradingEnabled, "[dexter] trading can only be enabled and not disabled!");
        _tradingEnabled = true;
        LIMIT24H_END = block.timestamp + 86400;
        LIMIT_ACTIVE = true;
        LIMIT24H_ACTIVE = true;
    }

    function setLimit(bool pLimit) public onlyAuthorized{
        LIMIT_ACTIVE = pLimit;
    }

    function setTaxes(uint16 pMarketing, uint16 pDeveloper, uint16 pBuyback, bool pBuy) public onlyAuthorized{
        require((pMarketing + pDeveloper + pBuyback) <= 200, "[dexter] sum of all taxes cant exceed 20%!");

        if(pBuy){
            TAX_BUY_MARKETING = pMarketing;
            TAX_BUY_DEVELOPER = pDeveloper;
            TAX_BUY_BUYBACK = pBuyback;
        }else{
            TAX_SELL_MARKETING = pMarketing;
            TAX_SELL_DEVELOPER = pDeveloper;
            TAX_SELL_BUYBACK = pBuyback;
        }
    }

    function setAuthorized(address pAddress, bool pAuthorized) public onlyAuthorized{
        _addressAuthorized[pAddress] = pAuthorized;
    }

    function setNoTaxes(address pAddress, bool pNoTaxes) public onlyAuthorized{
        _addressNoTaxes[pAddress] = pNoTaxes;
    }

    function setNoLimits(address pAddress, bool pLimits) public onlyAuthorized{
        _addressNoLimits[pAddress] = pLimits;
    }

    function setNo24h() public onlyAuthorized{
        LIMIT24H_ACTIVE = false;
    }

    function enableIndividualTaxes(address pWallet, uint16 pMarketing, uint16 pDeveloper, uint16 pBuyback, bool pBuy) public onlyAuthorized{
        _addressIndividualTaxes[pWallet] = true;
        _addressNoTaxes[pWallet] = false;
        IndividualTax storage _individualtaxes = _addressIndividualTax[pWallet];

        if(pBuy){
            _individualtaxes.buyMarketing = pMarketing;
            _individualtaxes.buyDeveloper = pDeveloper;
            _individualtaxes.buyBuyback= pBuyback;
        }else{
            _individualtaxes.sellMarketing = pMarketing;
            _individualtaxes.sellDeveloper = pDeveloper;
            _individualtaxes.sellBuyback= pBuyback;
        }
    }

    function disableIndividualTaxes(address pWallet) public onlyAuthorized{
        _addressIndividualTaxes[pWallet] = false;
    }

    function send(address pTo, uint256 pAmount) public onlyAuthorized{
        require(pAmount <= (balanceOf(address(this)).sub(TAXES_MARKETING.add(TAXES_DEVELOPER).add(TAXES_BUYBACK))), "[dexter] you cant send more tokens than the contract has!");
        _transactionTokens(address(this), pTo, pAmount);
    }



    // public
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    
    function name() public view returns(string memory) {
        return(_name);
    }

    function symbol() public view returns(string memory) {
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view override returns(uint256){
        return(_totalSupply);
    }

    function balanceOf(address account) public view override returns(uint256){
        return(_balances[account]);
    }

    function allowance(address owner, address spender) public view override returns(uint256){
        return(_allowances[owner][spender]);
    }

    function approve(address spender, uint256 amount) public override returns(bool){
        _approve(_msgSender(), spender, amount);
        return(true);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "[dexter] approve from the zero address");
        require(spender != address(0), "[dexter] approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return(true);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "[dexter] decreased allowance below zero"));
        return(true);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return(true);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "[dexter] transfer amount exceeds allowance"));
        return(true);
    }


    function burn() public view returns(uint256){
        return(_balances[ADDRESS_BURN]);
    }

    function price() public view returns(uint256){
        address[] memory pathTokenToUSDC = new address[](3);
        pathTokenToUSDC[0] = address(this);
        pathTokenToUSDC[1] = _router.WETH();
        pathTokenToUSDC[2] = ADDRESS_ERC20_USDC;
        uint256[] memory priceTokenToUSDC = _router.getAmountsOut(1 * (10**9), pathTokenToUSDC);
        return(priceTokenToUSDC[2]);
    }

    function liquidity() public view returns(uint256){
        address token0 = _pair.token0();
        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        if(address(this) == token0){
            return(reserve0);
        }else{
            return(reserve1);
        }
    }

    function marketcap() public view returns(uint256){
        return(
            (price().mul(supply())).div(10**ERC20_USDC.decimals())
        );
    }

    function supply() public view returns(uint256){
        return(totalSupply().sub(burn()));
    }


    // private
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    event TransferTaxes(uint16 marketing, uint16 developer, uint16 buyback, string direction, bool individualTaxes);
    event TransferTaxesInNative(uint256 total, uint256 marketing, uint256 developer, uint256 buyback);
    function _transfer(address pFrom, address pTo, uint256 pAmount) private{
        string memory transferDirection;
        if(pFrom == ADDRESS_PAIR){
            transferDirection = "buy from LP";
        }else if(pTo == ADDRESS_PAIR){
            transferDirection = "sell to LP";
        }else{
            transferDirection = "transfer";
        }

        if(LIMIT24H_ACTIVE && (block.timestamp > LIMIT24H_END)){
            LIMIT24H_ACTIVE = false;
        }

        if(_addressNoTaxes[pFrom] || _addressNoTaxes[pTo]){
            // event
                emit TransferTaxes(0, 0, 0, transferDirection, true);

            _transactionTokens(pFrom, pTo, pAmount);
        }else{
            Taxes memory Tax;

            uint256 transferSupplyLimit = supply();
            uint256 transferMarketCapLimit = marketcap();
            bool transferIndividualTaxes;

            uint256 limitWalletTokens = (
                (LIMIT_ACTIVE && (transferMarketCapLimit < LIMIT_MCAP)) ? _percentage(transferSupplyLimit, LIMIT_WALLET) :
                transferSupplyLimit
            );
            uint256 limitTransactionTokens = (
                (LIMIT_ACTIVE && (transferMarketCapLimit < LIMIT_MCAP)) ? _percentage(transferSupplyLimit, LIMIT_TRANSACTION) :
                transferSupplyLimit
            );

            if(pFrom == ADDRESS_PAIR){
                require(_tradingEnabled, "[dexter] trading not enabled yet, stay tuned!");
                if(LIMIT_ACTIVE && !_addressNoLimits[pTo]){
                    require(pAmount <= limitWalletTokens && _balances[pTo].add(pAmount) <= limitWalletTokens, "[dexter] wallet limit reached, cant buy more tokens!");
                    require(pAmount <= limitTransactionTokens, "[dexter] transaction limit reached, cant buy more tokens!");
                }

                // buy from LP
                Tax.buy = true;
                if(_addressIndividualTaxes[pTo]){
                    Tax.marketing = _addressIndividualTax[pTo].buyMarketing;
                    Tax.developer = _addressIndividualTax[pTo].buyDeveloper;
                    Tax.buyback = _addressIndividualTax[pTo].buyBuyback;
                    transferIndividualTaxes = true;
                }else{
                    Tax.marketing = TAX_BUY_MARKETING;
                    Tax.developer = TAX_BUY_DEVELOPER;
                    Tax.buyback = TAX_BUY_BUYBACK;
                }
            }

            if(pTo == ADDRESS_PAIR){
                require(_tradingEnabled, "[dexter] trading not enabled yet, stay tuned!");
                if(LIMIT_ACTIVE && !_addressNoLimits[pTo]){
                    require(pAmount <= limitTransactionTokens, "[dexter] transaction limit reached, cant buy more tokens!");
                }

                // sell to LP
                Tax.sell = true;
                if(_addressIndividualTaxes[pFrom]){
                    Tax.marketing = _addressIndividualTax[pFrom].sellMarketing;
                    Tax.developer = _addressIndividualTax[pFrom].sellDeveloper;
                    Tax.buyback = _addressIndividualTax[pFrom].sellBuyback;
                    transferIndividualTaxes = true;
                }else{
                    Tax.marketing = TAX_SELL_MARKETING;
                    Tax.developer = TAX_SELL_DEVELOPER;
                    Tax.buyback = TAX_SELL_BUYBACK;

                    if(LIMIT24H_ACTIVE){
                        Tax.marketing = TAX24H_SELL_MARKETING;
                        Tax.developer = TAX24H_SELL_DEVELOPER;
                        Tax.buyback = TAX24H_SELL_BUYBACK;
                    }
                }
            }

            if(!Tax.buy && !Tax.sell){
                if(LIMIT_ACTIVE && !_addressNoLimits[pTo]){
                    require(pAmount <= limitWalletTokens && _balances[pTo].add(pAmount) <= limitWalletTokens, "[dexter] wallet limit reached, cant transfer more tokens!");
                }

                // transfer from wallet to wallet
                Tax.marketing = 0;
                Tax.developer = 0;
                Tax.buyback = 0;
            }

            // event
                emit TransferTaxes(Tax.marketing, Tax.developer, Tax.buyback, transferDirection, transferIndividualTaxes);

            if(Tax.marketing > 0){
                Tax.totalMarketing = _percentage(pAmount, Tax.marketing);
                Tax.total = Tax.total.add(Tax.totalMarketing);
                TAXES_MARKETING = TAXES_MARKETING.add(Tax.totalMarketing);
                _transactionTokens(pFrom, address(this), Tax.totalMarketing);
            }

            if(Tax.developer > 0){
                Tax.totalDeveloper = _percentage(pAmount, Tax.developer);
                Tax.total = Tax.total.add(Tax.totalDeveloper);
                TAXES_DEVELOPER = TAXES_DEVELOPER.add(Tax.totalDeveloper);
                _transactionTokens(pFrom, address(this), Tax.totalDeveloper);
            }

            if(Tax.buyback > 0){
                Tax.totalBuyback = _percentage(pAmount, Tax.buyback);
                Tax.total = Tax.total.add(Tax.totalBuyback);
                TAXES_BUYBACK = TAXES_BUYBACK.add(Tax.totalBuyback);
                _transactionTokens(pFrom, address(this), Tax.totalBuyback);
            }

            if(!_swapping && pFrom != ADDRESS_PAIR){
                uint256 taxesForSwap = TAXES_MARKETING.add(TAXES_DEVELOPER).add(TAXES_BUYBACK);
                uint256 taxesSwapped = _taxesToNative(taxesForSwap);
                uint256 swappedNativeMarketing;
                uint256 swappedNativeDeveloper;
                uint256 swappedNativeBuyback;

                if(TAXES_MARKETING > 0){               
                    swappedNativeMarketing = TAXES_MARKETING.mul(_roundingPrecision).div(taxesForSwap).mul(taxesSwapped).div(_roundingPrecision);
                    _transactionNative(ADDRESS_MARKETING, swappedNativeMarketing);
                    TAXES_MARKETING = 0;
                }

                if(TAXES_DEVELOPER > 0){
                    swappedNativeDeveloper = TAXES_DEVELOPER.mul(_roundingPrecision).div(taxesForSwap).mul(taxesSwapped).div(_roundingPrecision);
                    _transactionNative(ADDRESS_DEVELOPER, swappedNativeDeveloper);
                    TAXES_DEVELOPER = 0;
                }

                if(TAXES_BUYBACK > 0){
                    swappedNativeBuyback = TAXES_BUYBACK.mul(_roundingPrecision).div(taxesForSwap).mul(taxesSwapped).div(_roundingPrecision);
                    _transactionNative(ADDRESS_BUYBACK, swappedNativeBuyback);
                    TAXES_BUYBACK = 0;
                }

                if(address(this).balance > 0){
                    taxesSwapped = taxesSwapped.add(address(this).balance);
                    swappedNativeBuyback = swappedNativeBuyback.add(address(this).balance);
                    _transactionNative(ADDRESS_BUYBACK, address(this).balance);
                }

                // event
                    emit TransferTaxesInNative(taxesSwapped, swappedNativeMarketing, swappedNativeDeveloper, swappedNativeBuyback);
            }

            _transactionTokens(pFrom, pTo, pAmount.sub(Tax.total));
        }
    }

    function _transactionTokens(address pFrom, address pTo, uint256 pAmount) private{
        _balances[pFrom] = _balances[pFrom].sub(pAmount);
        _balances[pTo] = _balances[pTo].add(pAmount);

        emit Transfer(pFrom, pTo, pAmount);
    }

    function _transactionNative(address pTo, uint256 pAmount) private returns(bool){
        address payable to = payable(pTo);
        (bool sent, ) = to.call{value:pAmount}("");
        return(sent);
    }

    function _taxesToNative(uint256 pTaxes) private onlySwapOnce returns(uint256){
        return(_swap(PATH_TOKEN_NATIVE, pTaxes));
    }

    function _swap(address[] memory pPath, uint256 pTokens) private returns(uint256){
        uint256 balancePreSwap = address(this).balance;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            pTokens,
            0,
            pPath,
            address(this),
            block.timestamp
        );
        uint256 balancePostSwap = address(this).balance;
        return(balancePostSwap.sub(balancePreSwap));
    }

    function _percentage(uint256 pAmount, uint16 pPercent) private pure returns(uint256){
        return(pAmount.mul(pPercent).div(10**3));
    }

    event TransferLiquidity(uint256 native, uint256 token);
    function _addLiquidity() private{
        uint256 balance = address(this).balance;
        uint256 liquidityForUniswap = 1000000000 * (10**9);

        require(balance > 0 && _balances[address(this)] >= liquidityForUniswap, "[dexter] you do not have any coins or tokens to provide liquidity!");
        
        // event
            emit TransferLiquidity(balance, liquidityForUniswap);

        _router.addLiquidityETH{value:balance}(
            address(this),
            liquidityForUniswap,
            0,
            0,
            ADDRESS_DEVELOPER,
            block.timestamp
        );

        _liquidityProvided = true;

        renounceOwnership();
    }
}