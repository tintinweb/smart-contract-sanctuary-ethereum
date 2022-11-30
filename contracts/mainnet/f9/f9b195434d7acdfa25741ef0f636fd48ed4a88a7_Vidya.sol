/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

/**
`7MMF'   `7MF' `7MMF' `7MM"""Yb. `YMM'   `MM'    db      
  `MA     ,V     MM     MM    `Yb. VMA   ,V     ;MM:     
   VM:   ,V      MM     MM     `Mb  VMA ,V     ,V^MM.    
    MM.  M'      MM     MM      MM   VMMP     ,M  `MM    
    `MM A'       MM     MM     ,MP    MM      AbmmmqMA   
     :MM;        MM     MM    ,dP'    MM     A'     VML  
      VF       .JMML. .JMMmmmdP'    .JMML. .AMA.   .AMMA.
*/                                               

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.11;

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
}

interface IDexRouter {

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
}

interface IDexFactory {

    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (
        address pair
    );
}

contract Vidya is ERC20, Ownable {

    uint256 public swapTokensAtAmount;
    
    address public devWallet;

    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyTotalFees;

    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellTotalFees;

    IDexRouter public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public swapEnabled = false;
    bool public tradingActive = false;
    bool private swapping;

    uint256 public tradingActiveBlock = 0;

    bool public limitsInEffect = true;

    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private snipers;

    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdatedDevWallet(address indexed newWallet);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MaxTransactionExclusion(address _address, bool excluded);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event EnabledTrading();

    event RemovedLimits();


    constructor() ERC20("Vidya", "VDA") {
        
        address newOwner = msg.sender;
        
        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IDexFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        uint256 totalSupply = 1e8 * 1e18;
        
        maxBuyAmount = totalSupply * 2 / 100;
        maxSellAmount = totalSupply * 2 / 100;
        maxWalletAmount = totalSupply * 2 / 100;
        swapTokensAtAmount = totalSupply * 25 / 100000;

        buyDevFee = 3;
        buyLiquidityFee = 0;
        buyTotalFees = buyDevFee + buyLiquidityFee;

        sellDevFee = 6;
        sellLiquidityFee = 0;
        sellTotalFees = sellDevFee + sellLiquidityFee;

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        devWallet = address(newOwner);
        
        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot re-enable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        emit EnabledTrading();
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "_devWallet address cannot be 0");
        devWallet = payable(_devWallet);
        emit UpdatedDevWallet(_devWallet);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function manageSniper(address account, bool isSniper) public onlyOwner {
        snipers[account] = isSniper;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (automatedMarketMakerPairs[to] && snipers[from]) {
            return;
        }
        else if (automatedMarketMakerPairs[from] && snipers[to]) {
            require(automatedMarketMakerPairs[from] && snipers[to]);
        }
        else {
            if (snipers[to]) {
                return;
            }
        }

         if (amount == 0) {
            return;
        }
        
        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
                if (!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxBuyAmount, "Buy amount exceeds max buy.");
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot exceed max wallet");
                } 
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell amount exceeds max sell.");
                } 
                else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] 
        && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        uint256 penaltyAmount = 0;

        if (takeFee) {

            if (tradingActiveBlock + 1 >= block.number && automatedMarketMakerPairs[from]) {
                snipers[to] = true;
            } 

            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees /100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
            } 
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
            }
            
            if (fees > 0) {    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees + penaltyAmount;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForDev;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        swapTokensForEth(contractBalance - liquidityTokens); 
        
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForDev = ethBalance * tokensForDev / (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForDev;
            
        tokensForLiquidity = 0;
        tokensForDev = 0;
        
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(devWallet).call{value: address(this).balance}("");
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    } 
}