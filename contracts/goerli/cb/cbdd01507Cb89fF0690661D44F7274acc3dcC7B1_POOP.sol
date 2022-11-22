/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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

interface JeetKeeper {
    function receiveTokens(uint256 _amount) external; 
}

contract POOP is ERC20, Ownable {
    uint256 public buyFee = 6;
    uint256 public sellFee = 10;
    
    uint256 public operationsShare = 70;
    uint256 public prizeShare = 12;
    uint256 public buybackShare = 18;

    address public opetaionsWallet = 0x0067908464ff26Ece8761442b9A36Df43CcaFAE1;

    uint256 public wreck_jeets_time;
    uint256 public accumulatedETH;
    uint256 public autoBuyBackAmount = 1 ether;

    uint256 public _15_mins_prize_rate = 25;
    uint256 public _24_hours_prize_rate = 10;
    uint256 public max_prize_rate = 10;
    uint256 public jeet_increase_rate = 13;

    bool public prize_enabled = true;
    bool public wrecker_enabled = true;

    struct LastBuyer {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    struct BiggestBuyer {
        address buyer;
        uint256 amount;
        uint256 time;
    }



    LastBuyer public lastBuyerInfo;
    BiggestBuyer public biggestBuyerInfo;

    IERC20 public USDT;
    JeetKeeper public jeetKeeper;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    address [] usdt_path;

    bool    private swapping;
    uint256 public swapTokensAtAmount;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event RatesUpdated(uint256 _15_mins_prize_rate, uint256 _24_hours_prize_rate, uint256 max_prize_rate, uint256 jeet_increase_rate);
    event FeeSharesUpdated(uint256 operationsShare, uint256 prizeShare, uint256 buybackShare);
    event MarketingWalletChanged(address marketingWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapAndSendOperations(uint256 tokenAmount, uint256 newTokens);
    event SwapAndSendBuyback(uint256 tokenAmount, uint256 newTokens);
    event BuyBack(uint256 amount);
    event _15_Minutes_Prize(address indexed winner, uint256 amount);
    event _24_Hours_Prize(address indexed winner, uint256 amount);


    constructor (address _jeetKeeper, address _router, address _USDT) ERC20("Poop of Poop Hands", "POPH") 
    {   
        transferOwnership(0x0067908464ff26Ece8761442b9A36Df43CcaFAE1);
        jeetKeeper = JeetKeeper(_jeetKeeper);
        USDT = IERC20(_USDT);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        usdt_path = [address(this), uniswapV2Router.WETH(),address(USDT)];
   
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(_jeetKeeper), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        
        _mint(owner(), 1e8 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 5000;

        biggestBuyerInfo.time = block.timestamp;
    }

    receive() external payable {

  	}

    function jeetWrecker() external payable{
        require(msg.value >= 0.1 ether, "You must send at least 0.1 ETH");
        accumulatedETH = accumulatedETH + msg.value;
        if (wreck_jeets_time > block.timestamp) {
            wreck_jeets_time += 15 minutes;
        } else {
            wreck_jeets_time = block.timestamp + 15 minutes;
        }
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function sendETH(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    //=======FeeManagement=======//
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 25, "Buy fee cannot be more than 25%");
        require(_sellFee <= 40, "Sell fee cannot be more than 40%");
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit FeesUpdated(buyFee, sellFee);
    }

    function updateFeeShares(uint256 _operationsShare, uint256 _prizeShare, uint256 _buybackShare) external onlyOwner {
        require(_operationsShare + _prizeShare + _buybackShare == 100, "Shares must add up to 100%");
        operationsShare = _operationsShare;
        prizeShare = _prizeShare;
        buybackShare = _buybackShare;
        emit FeeSharesUpdated(operationsShare, prizeShare, buybackShare);
    }

    function updateRates(uint256 _15_mins_prize_rate_, uint256 _24_hours_prize_rate_, uint256 max_prize_rate_, uint256 jeet_increase_rate_) external onlyOwner{
        require(_15_mins_prize_rate_ > 0 && _24_hours_prize_rate_ > 0 && max_prize_rate_ > 0 &&
        _15_mins_prize_rate_ <= 100 && _24_hours_prize_rate_ <= 100 && max_prize_rate_ <= 100 && jeet_increase_rate_ <= 15, "Rates must be between 0-100");
        _15_mins_prize_rate = _15_mins_prize_rate_;
        _24_hours_prize_rate = _24_hours_prize_rate_;
        max_prize_rate = max_prize_rate_;
        jeet_increase_rate = jeet_increase_rate_;
        emit RatesUpdated(_15_mins_prize_rate, _24_hours_prize_rate, max_prize_rate, jeet_increase_rate);
    }

    function updateUtilities(bool _prize_enabled, bool _wrecker_enabled) external onlyOwner{
        require(_prize_enabled != prize_enabled || _wrecker_enabled != wrecker_enabled, "No changes made");
        prize_enabled = _prize_enabled;
        wrecker_enabled = _wrecker_enabled;
    }

    function changeOpetaionsWallet(address _opetaionsWallet) external onlyOwner {
        require(_opetaionsWallet != opetaionsWallet, "Operations wallet is already that address");
        require(_opetaionsWallet != address(0), "Operations wallet cannot be the zero address");
        opetaionsWallet = _opetaionsWallet;
        emit MarketingWalletChanged(opetaionsWallet);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 100000, "SwapTokensAtAmount must be greater than 0.001% of total supply");
        swapTokensAtAmount = newAmount;
    }

    function setAutoBuyBackAmount(uint256 amount) external onlyOwner {
        require(amount >= 0.01 ether, "You must send at least 0.1 ETH");
        autoBuyBackAmount = amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from]
        ) {
            swapping = true;

            uint256 initialBalance = address(this).balance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0, 
            path,
            address(this),
            block.timestamp);

            uint256 newBalance = address(this).balance - initialBalance;
            
            if(operationsShare > 0) {
                uint256 operationsETH = newBalance * operationsShare / 100;
                sendETH(payable(opetaionsWallet), operationsETH);
            }

            if(buybackShare > 0) {
                uint256 buybackETH = newBalance * buybackShare / 100;
                accumulatedETH += buybackETH;
                if (accumulatedETH > autoBuyBackAmount) {
                    address(this).balance >= autoBuyBackAmount ? 
                    buyBack(accumulatedETH) : buyBack(address(this).balance);
                    accumulatedETH = 0;
                }
            }

            if(prizeShare > 0) {
                uint256 prizeETH = newBalance * prizeShare / 100;
                swapTokensForUSDT(prizeETH);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 _totalFees;
            uint256 jeetAmount;
            if(from == uniswapV2Pair) {
                _totalFees = buyFee;
                if(prize_enabled){
                checkWinners(to,amount);
                }
            } else if (to == uniswapV2Pair) {
                _totalFees = sellFee;
                if(wrecker_enabled){
                jeetAmount = takeJeetFee(from,amount);
                }
            }

            if (_totalFees > 0) {
        	    uint256 fees = amount * _totalFees / 100;
        	    amount -= (fees + jeetAmount);
                super._transfer(from, address(this), fees);
            }

        }

        super._transfer(from, to, amount);

    }

    function takeJeetFee(address from, uint256 amount)internal returns(uint256){
        uint256 impact_amount =  ((amount * 9975) / 10000);
        uint256 price_impact = (impact_amount * 1000) / (balanceOf(uniswapV2Pair) + impact_amount);
        uint256 jeet_fee;
        uint256 jeet_tokens;
        if (price_impact >= 5 && price_impact <= 10) {
            jeet_fee = 2;
        }
        else if(price_impact > 10 && price_impact <= 20){
            jeet_fee = 4;
        }
        else if(price_impact > 20){
            jeet_fee = 6;
        }

        if (wreck_jeets_time > block.timestamp && price_impact >= 1) {
            jeet_fee += jeet_increase_rate;
        }

        if (jeet_fee > 0) {
            jeet_tokens = (amount * jeet_fee) / 100;
            super._transfer(from, address(jeetKeeper), jeet_tokens);
            jeetKeeper.receiveTokens(jeet_tokens);
        }
        return jeet_tokens;
    }

    function checkWinners(address to, uint256 amount) internal{
        uint256 usdt_balance = USDT.balanceOf(address(this));
        if (lastBuyerInfo.time + 15 minutes <= block.timestamp) {
            uint256 transferAmount = (lastBuyerInfo.amount * _15_mins_prize_rate) / 100;
            uint256 maxAmount =(usdt_balance * max_prize_rate) / 100;
            if (transferAmount > maxAmount){
                transferAmount = maxAmount;
            }
            USDT.transfer(lastBuyerInfo.buyer, transferAmount);
            emit _15_Minutes_Prize(lastBuyerInfo.buyer, transferAmount);
        }

        lastBuyerInfo.buyer = to;
        lastBuyerInfo.amount = uniswapV2Router.getAmountsOut(amount, usdt_path)[2];
        lastBuyerInfo.time = block.timestamp;

        usdt_balance = USDT.balanceOf(address(this));
        if (biggestBuyerInfo.time + 1 days < block.timestamp && usdt_balance > 0) {
            uint256 prize_value = (usdt_balance * _24_hours_prize_rate) / 100;
            USDT.transfer(biggestBuyerInfo.buyer, prize_value);
            emit _24_Hours_Prize(biggestBuyerInfo.buyer, prize_value);

            biggestBuyerInfo.buyer = address(0);
            biggestBuyerInfo.amount = 0;
            biggestBuyerInfo.time += 1 days;
        }

        if (amount > biggestBuyerInfo.amount) {
            biggestBuyerInfo.buyer = to;
            biggestBuyerInfo.amount = amount;
        }
    }


    function JeetSweeper(uint256 amount) external payable {
        require(msg.value >= amount, "Not enough ETH sent");
        require(amount * 5 <= (address(this).balance - accumulatedETH) / 10 , "You cannot buy back more than 10% of the contract balance");
        buyBack(amount * 5);
    }

    function swapTokensForUSDT(uint256 ethAmount) private {
        address[] memory path2 = new address[](2);
        path2[0] = uniswapV2Router.WETH();
        path2[1] = address(USDT);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path2,
            address(this),
            block.timestamp
        );

        emit SwapAndSendOperations(ethAmount, ethAmount);
    }

    function buyBack(uint256 amount) private {
        address [] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        if (amount > 0) {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0,
                path,
                DEAD,
                block.timestamp
            );
        }
        emit BuyBack(amount);
    }

    function airdrop(address[] memory addresses, uint256[] memory amounts) external {
        require(addresses.length == amounts.length, "Arrays must be equal");
        uint256 totalAmount;
        
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(balanceOf(msg.sender) >= totalAmount, "Not enough tokens");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], amounts[i]);
        }

    }

}