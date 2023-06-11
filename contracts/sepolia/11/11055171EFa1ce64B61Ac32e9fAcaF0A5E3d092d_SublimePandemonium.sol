/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT

/**

                        ░██████╗██╗░░░██╗██████╗░██╗░░░░░██╗███╗░░░███╗███████╗
                        ██╔════╝██║░░░██║██╔══██╗██║░░░░░██║████╗░████║██╔════╝
                        ╚█████╗░██║░░░██║██████╦╝██║░░░░░██║██╔████╔██║█████╗░░
                        ░╚═══██╗██║░░░██║██╔══██╗██║░░░░░██║██║╚██╔╝██║██╔══╝░░
                        ██████╔╝╚██████╔╝██████╦╝███████╗██║██║░╚═╝░██║███████╗
                        ╚═════╝░░╚═════╝░╚═════╝░╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝

        ██████╗░░█████╗░███╗░░██╗██████╗░███████╗███╗░░░███╗░█████╗░███╗░░██╗██╗██╗░░░██╗███╗░░░███╗
        ██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔════╝████╗░████║██╔══██╗████╗░██║██║██║░░░██║████╗░████║
        ██████╔╝███████║██╔██╗██║██║░░██║█████╗░░██╔████╔██║██║░░██║██╔██╗██║██║██║░░░██║██╔████╔██║
        ██╔═══╝░██╔══██║██║╚████║██║░░██║██╔══╝░░██║╚██╔╝██║██║░░██║██║╚████║██║██║░░░██║██║╚██╔╝██║
        ██║░░░░░██║░░██║██║░╚███║██████╔╝███████╗██║░╚═╝░██║╚█████╔╝██║░╚███║██║╚██████╔╝██║░╚═╝░██║
        ╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝                                                                                     


                    ✅ Website    https://sublimepandemonium.com        ⭐️⭐️⭐️
                    ✅ Telegram   https://t.me/SublimePandemonium       ⭐️⭐️⭐️
                    ✅ Game       https://play.google.com/store/games   ⭐️⭐️⭐️

*/

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

library Address {
    function sendValue(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        return success;
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

contract SublimePandemonium is Context, IERC20, Ownable {
    using Address for address;
    using Address for address payable;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    
    mapping (address => bool) private _botTrap;
    uint256 private launchTime;

    string private _name     = "Sublime Pandemonium";
    string private _symbol   = "SUBLIME";
    uint8  private _decimals = 6;

    // Sepolia addresses
    address public Wallet_Marketing = 0xF6459573d18443696A71B3453163F0399BE5011A;
    address public Wallet_Development = 0x6fdC58b7ED25278B6c42fdB32E6dB8A3439606eD;
    address public Wallet_Liquidity = 0xBcB6105C5FA3714761255A9435e16a7dc6c38D30;

    address public Wallet_Burn = 0x000000000000000000000000000000000000dEaD;

    address public Contract_Presale;
    address public Contract_NFTMarketplace;
    address public Contract_PVP;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _totalSupply = __amount(1000000);

    uint256 private _maxWalletToken;
    uint256 private _maxTxAmount;

    uint256 private marketingFeeOnBuy;
    uint256 private marketingFeeOnSell;
    
    uint256 private developmentFeeOnBuy;
    uint256 private developmentFeeOnSell;

    uint256 private liquidityFeeOnBuy;
    uint256 private liquidityFeeOnSell;

    uint256 private _marketingFee;
    uint256 private _developmentFee;
    uint256 private _liquidityFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquify;
    bool public tradingEnabled;
    uint256 public swapTokensAtAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndSend(uint256 tokens, address wallet, uint256 amount);
    event PresaleAddressChanged(address previous, address current);
    event NFTMarketplaceAddressChanged(address previous, address current);
    event PVPAddressChanged(address previous, address current);

    constructor() {

        address router;
        if (block.chainid == 56) {
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;  // BSC
        } else if (block.chainid == 97) {
            router =  0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC TESTNET
        } else if (block.chainid == 11155111) {
            router = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;  // SEPOLIA
        } else {
            revert();
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), MAX);

        // BUY --> 8%      SELL --> 10%      TRANSFER --> 5%
        marketingFeeOnBuy = 3;
        marketingFeeOnSell = 4;
        
        developmentFeeOnBuy = 2;
        developmentFeeOnSell = 2;

        liquidityFeeOnBuy = 3;
        liquidityFeeOnSell = 4;

        _maxWalletToken = __amount(1900);
        _maxTxAmount = __amount(1900);
        swapTokensAtAmount = __amount(2222);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[Wallet_Marketing] = true;
        _isExcludedFromFees[Wallet_Liquidity] = true;
        _isExcludedFromFees[Wallet_Development] = true;
        _isExcludedFromFees[Wallet_Burn] = true;
        _isExcludedFromFees[address(this)] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tMarketing, uint256 tDevelopment, uint256 tLiquidity) = _getTValues(tAmount);
        return (tTransferAmount, tMarketing, tDevelopment, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tDevelopment = calculateDevelopmentFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tMarketing - tDevelopment - tLiquidity;
        return (tTransferAmount, tMarketing, tDevelopment, tLiquidity);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount * _marketingFee / 100;
    }

    function calculateDevelopmentFee(uint256 _amount) private view returns (uint256) {
        return _amount * _developmentFee / 100;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 100;
    }

    function removeAllFee() private {
        if(_marketingFee == 0 && _developmentFee == 0 && _liquidityFee == 0) return;
        
        _marketingFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
    }

    function setBuyFee() private{
        if(_marketingFee == marketingFeeOnBuy && _developmentFee == developmentFeeOnBuy && _liquidityFee == liquidityFeeOnBuy) return;

        _marketingFee = marketingFeeOnBuy;
        _developmentFee = developmentFeeOnBuy;
        _liquidityFee = liquidityFeeOnBuy;
    }

    function setSellFee() private{
        if(_marketingFee == marketingFeeOnSell && _developmentFee == developmentFeeOnSell && _liquidityFee == liquidityFeeOnSell) return;

        _marketingFee = marketingFeeOnSell;
        _developmentFee = developmentFeeOnSell;
        _liquidityFee = liquidityFeeOnSell;
    }

    function setTransferFee() private{
        _marketingFee = marketingFeeOnBuy;
        _developmentFee = developmentFeeOnBuy;
        _liquidityFee = 0;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function maxWalletAmount() public view returns(uint256) {
        return _maxWalletToken;
    }

    function maxTxAmount() public view returns(uint256) {
        return _maxTxAmount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading is already enabled");
        _maxWalletToken = __amount(30000);
        _maxTxAmount = __amount(20000);
        launchTime = block.timestamp;
        tradingEnabled = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(tradingEnabled, "Trading is not enabled yet");
        }

        if (
            to != owner() &&
            to != address(this) &&
            to != uniswapV2Pair &&
            to != Wallet_Burn &&
            from != owner()
        ) {
            uint256 heldTokens = balanceOf(to);
                require((heldTokens + amount) <= _maxWalletToken, "Over wallet limit.");
        }

        if (from != owner())
            require(amount <= _maxTxAmount, "Over transaction limit.");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if (overMinTokenBalance && !inSwapAndLiquify && to == uniswapV2Pair) {
            inSwapAndLiquify = true;

            if (contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}

            swapAndSend(contractTokenBalance);
            
            inSwapAndLiquify = false;
        }

        _tokenTransfer(from, to, amount);

    }

    function swapAndSend(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        uint256 toMarketing = newBalance * 40 / 100;
        uint256 toDevelopment = newBalance * 20 / 100;
        uint256 toLiquidity = newBalance * 40 / 100;

        payable(Wallet_Marketing).sendValue(toMarketing);
        emit SwapAndSend(tokenAmount * 40 / 100, Wallet_Marketing, toMarketing);

        payable(Wallet_Development).sendValue(toDevelopment);
        emit SwapAndSend(tokenAmount * 20 / 100, Wallet_Development, toDevelopment);

        payable(Wallet_Liquidity).sendValue(toLiquidity);
        emit SwapAndSend(tokenAmount * 40 / 100, Wallet_Liquidity, toLiquidity);

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            removeAllFee();
        } else if (recipient == uniswapV2Pair) {
            require (!_botTrap[sender], "You are in the bot blacklist.");
            setSellFee();
        } else if (sender == uniswapV2Pair) {
            if (block.timestamp < launchTime + 7)
                _botTrap[recipient] = true;
            setBuyFee();
        } else {
            setTransferFee();
        }

        (uint256 tTransferAmount, uint256 tMarketing, uint256 tDevelopment, uint256 tLiquidity) = _getValues(amount);
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + tTransferAmount;

        uint256 tokensFromFee = tMarketing + tDevelopment + tLiquidity;

        if (tokensFromFee > 0) {
            _balances[address(this)] = _balances[address(this)] + tokensFromFee;
        }

        emit Transfer(sender, recipient, tTransferAmount);

    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function changePresaleAddress(address _address) external onlyOwner {
        address previous = Contract_Presale;
        Contract_Presale = _address;
        _isExcludedFromFees[Contract_Presale] = true;
        emit PresaleAddressChanged(previous, _address);
    }

    function changeNFTMarketplaceAddress(address _address) external onlyOwner {
        address previous = Contract_NFTMarketplace;
        Contract_NFTMarketplace = _address;
        _isExcludedFromFees[Contract_NFTMarketplace] = true;
        emit NFTMarketplaceAddressChanged(previous, _address);
    }

    function changePVPAddress(address _address) external onlyOwner {
        address previous = Contract_PVP;
        Contract_PVP = _address;
        _isExcludedFromFees[Contract_PVP] = true;
        emit PVPAddressChanged(previous, _address);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
            _balances[Wallet_Burn] += amount;
        }

        emit Transfer(account, Wallet_Burn, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function __amount(uint256 _amount) private view returns (uint256) {
        return _amount * (10**_decimals);
    }
}