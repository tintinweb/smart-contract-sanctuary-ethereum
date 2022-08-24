/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

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

contract GameOfDragons is ERC20, Ownable {
    uint256 public buyFee = 92;
    uint256 public sellFee = 92;
    
    uint256 public liquidityShare = 16;
    uint256 public fee1Share = 42;
    uint256 public fee2Share = 42;

    address public fee1Wallet = 0x9F82E1a66BdB6A00b958c00eBC911D8305508962;
    address public fee2Wallet = 0x1B5A60c31f1425146b6219CE1db68a31173F8439;
    address public botFeeWallet = 0xc48b1e496Ed574BB9c8f7c98d9c058Ec047ae396;

    
    address public operator = 0x85abA2399478e65e21051eEf80A36fB5938345C0;
    address public newOwner = 0xD2a8093402912AeC59a95F55B1bB6F25D6fAf7C7;

    bool public walletToWalletTransferWithoutFee = false;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool   public  enableTrading;

    bool    private swapping;
    uint256 public swapTokensAtAmount;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

  
    uint256 public timeAntiBot = 30 ; 
    
    mapping(address => bool) _isBot;
    uint256 public launchTime = 0;
    
    bool public antibotSystemEnable = true;

    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    bool    public  maxTransactionLimitEnabled = true;
    uint256 public  maxTransactionAmountBuy  = 5 * (10**23); //0.5% of total supply 
    uint256 public  maxTransactionAmountSell = 5 * (10**23); //0.5% of total supply 

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event FeeSharesUpdated(uint256 liquidityShare, uint256 fee1Share, uint256 fee2Share);
    event Fee1WalletChanged(address fee1Wallet);
    event Fee2WalletChanged(address fee2Wallet);
    event BotFeeWalletChanged(address botFeeWallet);
    event OperatorWalletChanged(address operatorWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    //event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    //event SwapAndSendWallets(uint256 tokensSwapped, uint256 bnbSend);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludedFromMaxTransactionLimit(address indexed account, bool isExcluded);
    event MaxTransactionLimitRatesChanged(uint256 maxTransferRateBuy, uint256 maxTransferRateSell);
    event MaxTransactionLimitStateChanged(bool maxTransactionLimit);

    constructor () ERC20("Game Of Dragons", "$GOD") 
    {   
        newOwner = 0xD2a8093402912AeC59a95F55B1bB6F25D6fAf7C7;
        

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromMaxTxLimit[owner()] = true;
        _isExcludedFromMaxTxLimit[address(0)] = true;
        _isExcludedFromMaxTxLimit[address(this)] = true;
        _isExcludedFromMaxTxLimit[DEAD] = true;
        
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(0)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[DEAD] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
 
        _isExcludedFromFees[fee1Wallet] = true;
        _isExcludedFromFees[fee2Wallet] = true;
        _isExcludedFromFees[botFeeWallet] = true;
        _isExcludedFromFees[newOwner] = true;

        _isExcludedFromMaxWalletLimit[fee1Wallet] = true;
        _isExcludedFromMaxWalletLimit[fee2Wallet] = true;
        _isExcludedFromMaxWalletLimit[botFeeWallet] = true;
        _isExcludedFromMaxWalletLimit[newOwner] = true;

        _isExcludedFromMaxTxLimit[fee1Wallet] = true;
        _isExcludedFromMaxTxLimit[fee2Wallet] = true;
        _isExcludedFromMaxTxLimit[botFeeWallet] = true;
        _isExcludedFromMaxTxLimit[newOwner] = true;
        
        
        _mint(newOwner, 100000000 * (10**18));
        swapTokensAtAmount = totalSupply() / 2000;

        operator = _msgSender();
    }


    

    modifier onlyOperator(){
        require(operator == _msgSender(),"Caller is not the Operator");
        _;
    }

    modifier onlyAuthorize(){
        require(operator == _msgSender() || owner() == _msgSender(),"Caller is not the Operator");
        _;
    }

    function changeOperatorWallet(address newAddress) external onlyOperator{
        require(newAddress != operator,"Operator Address is already same");
        require(!isContract(newAddress), "Operator wallet cannot be a contract");
        operator = newAddress;
        emit OperatorWalletChanged(operator);
    }


    receive() external payable {

  	}

    function setOpenTrading() external onlyAuthorize{
        require(enableTrading == false, "Trading is already enabled");
        enableTrading = true;
        launchTime = block.timestamp;

    }  


    function excludeAntibot(address ac) public onlyOwner {
        require(_isBot[ac], "not bot");
        _isBot[ac] = false;
    }


    function isBot(address acc) public view returns(bool) {
        return _isBot[acc];
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

    function sendETH(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function updateUniswapV2Router(address newAddress) external onlyOperator {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOperator {
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
        require(_buyFee <= 250 && _sellFee <= 250, "Fees must be less than 25%");
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit FeesUpdated(buyFee, sellFee);
    }

    function updateFeeShares(uint256 _fee1FeeShare, uint256 _liquidityFeeShare, uint256 _fee2Share) external onlyOwner {
        require(_fee1FeeShare + _liquidityFeeShare + _fee2Share == 100, "Fee shares must add up to 100");
        fee1Share = _fee1FeeShare;
        liquidityShare = _liquidityFeeShare;
        fee2Share = _fee2Share;
        emit FeeSharesUpdated(fee1Share, liquidityShare, fee2Share);
    }

    function enableWalletToWalletTransferWithoutFee(bool enable) external onlyOwner {
        require(walletToWalletTransferWithoutFee != enable, "Wallet to wallet transfer without fee is already set to that value");
        walletToWalletTransferWithoutFee = enable;
    }

    function changeFee1Wallet(address _fee1Wallet) external onlyOwner {
        require(_fee1Wallet != fee1Wallet, "fee1 wallet is already that address");
        require(!isContract(_fee1Wallet), "fee1 wallet cannot be a contract");
        fee1Wallet = _fee1Wallet;
        emit Fee1WalletChanged(fee1Wallet);
    }

    function changeFee2Wallet(address _fee2Wallet) external onlyOwner {
        require(_fee2Wallet != fee2Wallet, "fee2 wallet is already that address");
        require(!isContract(_fee2Wallet), "fee2 wallet cannot be a contract");
        fee2Wallet = _fee2Wallet;
        emit Fee2WalletChanged(fee2Wallet);
    }

    function changeBotFee2Wallet(address _botFeeWallet) external onlyOwner {
        require(_botFeeWallet != botFeeWallet, "botFee wallet is already that address");
        require(!isContract(_botFeeWallet), "botFee wallet cannot be a contract");
        botFeeWallet = _botFeeWallet;
        emit BotFeeWalletChanged(botFeeWallet);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       

        if (launchTime > 0) {
            if(block.timestamp - launchTime <= timeAntiBot && from == uniswapV2Pair && antibotSystemEnable) {
    
                _isBot[to] = true;
            }
        }


        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }



        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(enableTrading, "Trading is not enabled");
        }

        if (maxWalletLimitEnabled) {
            if (_isExcludedFromMaxWalletLimit[from] == false
                && _isExcludedFromMaxWalletLimit[to] == false &&
                to != uniswapV2Pair
            ) {
                uint balance  = balanceOf(to);
                require(balance + amount <= maxWalletAmount(), "MaxWallet: Transfer amount exceeds the maxWalletAmount");
            }
        }

        if (maxTransactionLimitEnabled) 
        {
            if ((from == uniswapV2Pair || to == uniswapV2Pair) &&
                _isExcludedFromMaxTxLimit[from] == false && 
                _isExcludedFromMaxTxLimit[to]   == false) 
            {
                if (from == uniswapV2Pair) {
                    require(
                        amount <= maxTransactionAmountBuy,  
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                } else {
                    require(
                        amount <= maxTransactionAmountSell, 
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                }
            }
        }

        



		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to]
        ) {
            swapping = true;

            uint256 liquidityTokens       = contractTokenBalance * liquidityShare / 100 / 2;
            uint256 liquidityTokensForETH = contractTokenBalance * liquidityShare / 100 / 2;
            
            uint256 fee1Tokens = contractTokenBalance * fee1Share / 100;
            uint256 fee2Tokens = contractTokenBalance * fee2Share / 100;

            uint256 tokensToSwap  = liquidityTokensForETH + fee1Tokens + fee2Tokens;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            uint256 initialBalance = address(this).balance;

            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSwap,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp);
            
            uint256 newBalance = address(this).balance - initialBalance;

            if (liquidityShare > 0)
            {   
                uint256 liquidityETH = newBalance * liquidityTokensForETH / tokensToSwap; 

                uniswapV2Router.addLiquidityETH{value: liquidityETH}(
                    address(this),
                    liquidityTokens,
                    0, // slippage is unavoidable
                    0, // slippage is unavoidable
                    DEAD,
                    block.timestamp
                );
            }


            if(fee1Share > 0) {
                uint256 fee1ETH = newBalance * fee1Tokens / tokensToSwap;
                sendETH(payable(fee1Wallet), fee1ETH);

            }

            if(fee2Share > 0) {
                uint256 fee2ETH = newBalance * fee2Tokens / tokensToSwap;
                sendETH(payable(fee2Wallet), fee2ETH);

            }

/////////////

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(walletToWalletTransferWithoutFee && from != uniswapV2Pair && to != uniswapV2Pair) {
            takeFee = false;
        }
        

        if(takeFee) {
            uint256 _totalFees;
            if (_isBot[to] && from == uniswapV2Pair){
                _totalFees = 900;
                uint256 fees = amount * _totalFees / 1000;
                amount = amount - fees;
                super._transfer(from, botFeeWallet, fees);
            }
            
            else{
                if(from == uniswapV2Pair) {
                _totalFees = buyFee; 
                } 

                else {
                _totalFees = sellFee;
                }
            uint256 fees = amount * _totalFees / 1000;
        	amount = amount - fees;
            super._transfer(from, address(this), fees);
            }


        }


        super._transfer(from, to, amount);

    }

    //=======Swap=======//

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 100000, "SwapTokensAtAmount must be greater than 0.001% of total supply");
        swapTokensAtAmount = newAmount;
    }

    //=======MaxWallet=======//
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    bool    public maxWalletLimitEnabled = true;
    uint256 private maxWalletLimitRate   = 50;

    event ExcludedFromMaxWalletLimit(address indexed account, bool isExcluded);
    event MaxWalletLimitRateChanged(uint256 maxWalletLimitRate);
    event MaxWalletLimitStateChanged(bool maxWalletLimit);

    function setEnableMaxWalletLimit(bool enable) external onlyOwner {
        require(enable != maxWalletLimitEnabled, "Max wallet limit is already that state");
        maxWalletLimitEnabled = enable;
        emit MaxWalletLimitStateChanged(maxWalletLimitEnabled);
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }

    function maxWalletAmount() public view returns (uint256) {
        return totalSupply() * maxWalletLimitRate / 1000;
    }

    function setMaxWalletRate_Denominator1000(uint256 _val) external onlyOwner {
        require(_val >= 10, "Max wallet percentage cannot be lower than 1%");
        maxWalletLimitRate = _val;
        emit MaxWalletLimitRateChanged(maxWalletLimitRate);
    }

    function setExcludeFromMaxWallet(address account, bool exclude) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != exclude, "Account is already set to that state");
        _isExcludedFromMaxWalletLimit[account] = exclude;
        emit ExcludedFromMaxWalletLimit(account, exclude);
    }

    //=======MaxTransaction=======//
    function setEnableMaxTransactionLimit(bool enable) external onlyOwner {
        require(
            enable != maxTransactionLimitEnabled, 
            "Max transaction limit is already set to that state"
        );
        maxTransactionLimitEnabled = enable;
        emit MaxTransactionLimitStateChanged(maxTransactionLimitEnabled);
    }

    function setMaxTransactionAmounts(uint256 _maxTransactionAmountBuy, uint256 _maxTransactionAmountSell) external onlyOwner {
        require(
            _maxTransactionAmountBuy  >= totalSupply() / (10 ** decimals()) / 1000 && 
            _maxTransactionAmountSell >= totalSupply() / (10 ** decimals()) / 1000, 
            "Max Transaction limis cannot be lower than 0.1% of total supply"
        ); 
        maxTransactionAmountBuy  = _maxTransactionAmountBuy  * (10 ** decimals());
        maxTransactionAmountSell = _maxTransactionAmountSell * (10 ** decimals());
        emit MaxTransactionLimitRatesChanged(maxTransactionAmountBuy, maxTransactionAmountSell);
    }

    function setExcludeFromMaxTransactionLimit(address account, bool exclude) external onlyOwner {
        require(
            _isExcludedFromMaxTxLimit[account] != exclude, 
            "Account is already set to that state"
        );
        _isExcludedFromMaxTxLimit[account] = exclude;
        emit ExcludedFromMaxTransactionLimit(account, exclude);
    }

    function isExcludedFromMaxTransaction(address account) public view returns(bool) {
        return _isExcludedFromMaxTxLimit[account];
    }
}