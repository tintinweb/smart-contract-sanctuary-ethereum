/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

/*
Project: MetaWeb3Pad
Contract Author: ARRNAYA (SAFU DEV)
Telegram: @ARRN4YA
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

contract MetaWeb3Pad is ERC20, Ownable {
    uint256 public  lpTaxOnBuy = 1;
    uint256 public  lpTaxOnSell = 1;

    uint256 public  marketingTaxOnBuy = 2;
    uint256 public  marketingTaxOnSell = 2;

    uint256 private _totalFeesOnBuy = lpTaxOnBuy + marketingTaxOnBuy;
    uint256 private _totalFeesOnSell = lpTaxOnSell + marketingTaxOnSell;

    address public marketingWallet;

    address public operator;

    bool public noTaxOnWalletToWallet;
    bool public tradingOpen = false;

    uint256 public launchedAt = 0;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public swapTokensAtAmount;
    bool    public swapWithLimit;
    bool    private swapping;
    bool    public swapEnabled = true;

    uint256 public maxTxn = totalSupply() / 100; // 1% of total supply
    uint256 public maxWallet = totalSupply() / 50; // 2% of total supply

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTxn;
    mapping (address => bool) public _isExcludedMaxWallet;
    mapping (address => bool) public automatedMarketMakerPairs;

    // Events log the transaction on blockchain and are accessible using address of the contract 
    // till the contract is present on the blockchain
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludedmaxLimits(address indexed account, bool isExcluded);
    event MaxWalletUpdated(uint256 maxWallet);
    event MaxAmountUpdated(uint256 maxTxn);
    event MarketingWalletChanged(address marketingWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event UpdateBuyFees(uint256 lpTaxOnBuy, uint256 marketingTaxOnBuy);
    event UpdateSellFees(uint256 lpTaxOnSell, uint256 marketingTaxOnSell);
    event ProcessMarketingTax(uint256 sentBNB);

    constructor (address newOwner, address router_)ERC20("MetaWeb3Pad",  "MetaWeb3Pad"){  

        _mint(newOwner, 1_000_000_000 * (10 ** 18));

        operator = msg.sender;
        marketingWallet = 0x34B1E990E6A0ED316C169D4e5Cac0BEDdD11139C;// Address to collect marketing taxes in BNB

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);// Remember to set correct router while deploying
       

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[newOwner] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;

        _isExcludedMaxWallet[newOwner] = true;
        _isExcludedMaxWallet[owner()] = true;
        _isExcludedMaxWallet[DEAD] = true;
        _isExcludedMaxWallet[address(this)] = true;

        _isExcludedMaxTxn[newOwner] = true;
        _isExcludedMaxTxn[owner()] = true;
        _isExcludedMaxTxn[DEAD] = true;
        _isExcludedMaxTxn[address(this)] = true;
        
        swapWithLimit = false;
        swapTokensAtAmount = totalSupply() / 5000; // 0.02% of total supply
    }

    modifier onlyOwnerOrOperator(){
        require(operator == _msgSender() || owner() == _msgSender(),"Only either owner or operator can call this function!");
        _;
    }

    receive() external payable {

  	}

    function claimStuckTokens(address token) external onlyOwnerOrOperator {
        require(token != address(this), "Native tokens can't be withdrawan!");
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

    function sendBNB(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    // Open Trading
    function _openTrading() public onlyOwner {
        tradingOpen = true;
        launchedAt = block.number;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwnerOrOperator {
        require(newAddress != address(uniswapV2Router), "The router is already set to this address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwnerOrOperator {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to this address");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    //=======FeeManagement=======//
    function excludeFromFees(address account) external onlyOwner {
        require(!_isExcludedFromFees[account] , "Account is already excluded from fees");
        _isExcludedFromFees[account] = true;

        emit ExcludeFromFees(account, true);
    }

    function excludeFromLimits(address updAds, bool isEx) public onlyOwner {
        require(!_isExcludedMaxTxn[updAds], "Already excluded!");
        require(!_isExcludedMaxWallet[updAds], "Already excluded!");
        _isExcludedMaxTxn[updAds] = isEx;
        _isExcludedMaxWallet[updAds] = isEx;
        emit ExcludedmaxLimits(updAds, isEx);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedMaxTxn(address account) public view returns(bool) {
        return _isExcludedMaxTxn[account];
    }

    function isExcludedMaxWallet(address account) public view returns(bool) {
        return _isExcludedMaxWallet[account];
    }       

    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= maxTxn/1e18, "Cannot lower maxTxn");
        maxTxn = newNum * (10**18);

        emit MaxAmountUpdated(newNum);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= maxWallet/1e18, "Can't lower maxWallet");
        maxWallet = newNum * (10**18);

        emit MaxWalletUpdated(newNum);
    }

    function updateBuyFees(uint256 _lpTaxOnBuy, uint256 _marketingTaxOnBuy) external onlyOwner {
        require(
            _lpTaxOnBuy + _marketingTaxOnBuy <= 15,
            "Can't set buy fees above 15%"
        );
        lpTaxOnBuy = _lpTaxOnBuy;
        marketingTaxOnBuy = _marketingTaxOnBuy;
        _totalFeesOnBuy   = lpTaxOnBuy + marketingTaxOnBuy;
        emit UpdateBuyFees(_lpTaxOnBuy, _marketingTaxOnBuy);
    }

    function updateSellFees(uint256 _lpTaxOnSell, uint256 _marketingTaxOnSell) external onlyOwner {
        require(
            _lpTaxOnSell + _marketingTaxOnSell <= 15,
            "Can't set sell fees above 15%"
        );
        lpTaxOnSell = _lpTaxOnSell;
        marketingTaxOnSell = _marketingTaxOnSell;
        _totalFeesOnSell   = lpTaxOnSell + marketingTaxOnSell;
        emit UpdateSellFees(_lpTaxOnSell, _marketingTaxOnSell);
    }

    // Only use if intending to switch all fees to zero
    function removeAllFee() external onlyOwner {
        // Buy fees
        lpTaxOnBuy = 0;
        marketingTaxOnBuy = 0;

        // Sell fees
        lpTaxOnSell = 0;
        marketingTaxOnSell = 0;
    }

    // only use if conducting a presale.
    function addPresaleAddressForExclusions(address presaleAddress, address presaleRouter) external onlyOwner {
        _isExcludedFromFees[presaleAddress] = true;
        _isExcludedMaxTxn[presaleAddress] = true;
        _isExcludedMaxWallet[presaleAddress] = true;
        _isExcludedFromFees[presaleRouter] = true;
        _isExcludedMaxTxn[presaleRouter] = true;
        _isExcludedMaxWallet[presaleRouter] = true;
    }

    function setNoTaxOnWalletToWallet(bool enable) external onlyOwner {
        require(noTaxOnWalletToWallet != enable, "Wallet to wallet transfer is not taxed already");
        noTaxOnWalletToWallet = enable;
    }

    //=======WalletManagement=======//
    function changeMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != marketingWallet, "Marketing wallet is already set to this address");
        require(!isContract(_marketingWallet), "Marketing wallet cannot be a contract");
        marketingWallet = _marketingWallet;
        emit MarketingWalletChanged(marketingWallet);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 100000, "SwapTokensAtAmount must be greater than 0.001% of total supply");
        swapTokensAtAmount = newAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(!_isExcludedFromFees[msg.sender]){
            require(tradingOpen,"Trading not open yet");
        }

        if(!_isExcludedMaxTxn[msg.sender] && !_isExcludedMaxWallet[msg.sender]) {
            require(amount <= maxTxn, "Transfer amount exceeds the maxTxnTransactionAmount.");
            require(amount + balanceOf(to) <= maxWallet, "Can't exceed maxWallet");
        }
    
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (swapEnabled && 
            canSwap &&
            !swapping &&
            from != uniswapV2Pair &&
            _totalFeesOnBuy + _totalFeesOnSell > 0
        ) {
            swapping = true;
            
            if (swapWithLimit) {
                contractTokenBalance = swapTokensAtAmount;
            }

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;
            uint256 liquidityShare = lpTaxOnBuy + lpTaxOnSell;
            uint256 marketingShare = marketingTaxOnBuy + marketingTaxOnSell;

            uint256 liquidityTokens;
            if(liquidityShare > 0) {
                liquidityTokens = (contractTokenBalance * liquidityShare) / totalFee;
                swapAndLiquify(liquidityTokens);
            }

            contractTokenBalance -= liquidityTokens;
            uint256 bnbShare = marketingShare;
            
            if(contractTokenBalance > 0 && bnbShare > 0) {
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

                if(marketingShare > 0) {
                    uint256 marketingBNB = (newBalance * marketingShare) / bnbShare;
                    sendBNB(payable(marketingWallet), marketingBNB);

                    emit ProcessMarketingTax(marketingBNB);
                }
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(noTaxOnWalletToWallet && from != uniswapV2Pair && to != uniswapV2Pair) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 _totalFees;
            if(from == uniswapV2Pair) {
                _totalFees = _totalFeesOnBuy;
            } else {
                _totalFees = _totalFeesOnSell;
            }
        	uint256 fees = (amount * _totalFees) / 100;
        	amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    //=======Swap=======//
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp);
        
        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
}