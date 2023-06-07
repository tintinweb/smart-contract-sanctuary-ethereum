/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: NOLICENSE
// https://thanoscoin.org

pragma solidity ^0.8.0;

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

    constructor() {
        _setOwner(_msgSender());
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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Thanos is Context, IERC20, Ownable {

    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    bool public swapEnabled;
    bool private swapping;

    IRouter private router;
    address private pair;

    uint8 private constant DECIMALS = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private constant T_TOTAL = 1e14 * 10**DECIMALS;

    uint256 public swapTokensAtAmount = 200_000_000_000 * 10**DECIMALS;

    
    address public constant ZERO_ADDRESS = address(0);
    address public marketingAddress = ZERO_ADDRESS;

    string private constant NAME = "Thanos";
    string private constant SYMBOL = "THANOS";


    enum ETransferType {
        Sell,
        Buy,
        Transfer
    }

    struct Taxes {
        uint16 marketing;
        uint16 liquidity;
    }

    uint8 public transferTaxesTier;
    Taxes public transferTaxes = Taxes(0,0);
    uint8 public buyTaxesTier;
    Taxes public buyTaxes;
    uint8 public sellTaxesTier;
    Taxes public sellTaxes;

    struct TotFeesPaidStruct{
        uint256 marketing;
        uint256 liquidity;
    }
    TotFeesPaidStruct public totFeesPaid;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address routerAddress) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        _balance[owner()] = T_TOTAL;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress]=true;
        etx(2);

        emit Transfer(address(0), owner(), T_TOTAL);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return NAME;
    }
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    //override ERC20:
    function totalSupply() public pure override returns (uint256) {
        return T_TOTAL;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");

        ETransferType transferType = ETransferType.Transfer;
        address trader = address(0);
        Taxes memory usedTaxes = transferTaxes;
        bool excludedFromFee = false;
        if (to == pair) {
            transferType = ETransferType.Sell;
            trader = from;
            usedTaxes = sellTaxes;
            excludedFromFee = _isExcludedFromFee[trader];
        } else if (from == pair) {
            transferType = ETransferType.Buy;
            trader = to;
            usedTaxes = buyTaxes;
            excludedFromFee = _isExcludedFromFee[trader];
        } else {
            usedTaxes = transferTaxes;
            excludedFromFee = _isExcludedFromFee[from] || _isExcludedFromFee[to];
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(transferType != ETransferType.Buy && !swapping && swapEnabled && canSwap && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }

        if (excludedFromFee || usedTaxes.marketing + usedTaxes.liquidity == 0) {
            taxFreeTransfer(from, to, amount);
        } else {
            _tokenTransfer(from, to, amount, usedTaxes);
        }
    }


    // this method is responsible for taking all fee
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, Taxes memory usedTaxes) private {

        uint256 tTransferAmount = tAmount;
        
        if(usedTaxes.liquidity != 0) {
            uint256 tLiquidity = tAmount * usedTaxes.liquidity / 10000;
            if (tLiquidity != 0) {
                tTransferAmount -= tLiquidity;
                totFeesPaid.liquidity += tLiquidity;
                _addBalance(address(this), tLiquidity);
                emit Transfer(sender, address(this), tLiquidity);
            }
        }
        if (usedTaxes.marketing != 0) {
            uint256 tMarketing = tAmount * usedTaxes.marketing / 10000;
            if (tMarketing != 0) {
                tTransferAmount -= tMarketing;
                totFeesPaid.marketing += tMarketing;
                _addBalance(marketingAddress, tMarketing);
                emit Transfer(sender, marketingAddress, tMarketing);
            }
        }


        _reduceBalance(sender, tAmount);
        if (tTransferAmount != 0) {
            _addBalance(recipient, tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap{
         //calculate how many tokens we need to exchange
        uint256 tokensToSwap = contractTokenBalance / 2;
        uint256 otherHalfOfTokens = tokensToSwap;
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokensToSwap, address(this));
        uint256 newBalance = address(this).balance - (initialBalance);
        addLiquidity(otherHalfOfTokens, newBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            payable(recipient),
            block.timestamp
        );
    }

    function getTaxesValueByTier(uint8 tier) private view returns(uint16, uint16) {
        if (tier == 0) {
            return (0, 0);
        }
        if (tier == 1) {
            if (marketingAddress == ZERO_ADDRESS) {
                return (0, 40);
            }
            return (20, 20);
        }
        
        if (marketingAddress == ZERO_ADDRESS) {
            return (0, 300);
        }
        return (100, 200);
    }

    function checkAndUpdateTaxes(bool buyChanged, bool sellChanged, bool transferChanged) private {
        if (buyChanged) {
            (uint16 v1, uint16 v2) = getTaxesValueByTier(buyTaxesTier);
            buyTaxes = Taxes(v1, v2);
        }
        if (sellChanged) {
            (uint16 v1, uint16 v2) = getTaxesValueByTier(sellTaxesTier);
            sellTaxes = Taxes(v1, v2);
        }
        if (transferChanged) {
            (uint16 v1, uint16 v2) = getTaxesValueByTier(transferTaxesTier);
            transferTaxes = Taxes(v1, v2);
        }
    }

    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet, "Wallet already set");
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress] = true;
        checkAndUpdateTaxes(true, true, true);
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**DECIMALS;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, "Value already set");
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function taxFreeTransfer(address sender, address recipient, uint256 tAmount) internal {
        _reduceBalance(sender, tAmount);
        _addBalance(recipient, tAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _addBalance(address account, uint256 tAmount) private {
        _balance[account] += tAmount;
    }

    function _reduceBalance(address account, uint256 tAmount) private {
        _balance[account] -= tAmount;
    }
    
    function airdropTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner{
        require(accounts.length == amounts.length, "Arrays must have the same size");
        for(uint256 i= 0; i < accounts.length; i++){
            taxFreeTransfer(msg.sender, accounts[i], amounts[i] * 10**DECIMALS);
        }
    }
    

    function dtx() public onlyOwner{
        buyTaxesTier = 0;
        sellTaxesTier = 0;
        transferTaxesTier = 0;
        checkAndUpdateTaxes(true, true, true);
    }

    function etx(uint8 taxesTier) public onlyOwner{
        require(taxesTier > 0 && taxesTier <=2);
        buyTaxesTier = taxesTier;
        sellTaxesTier = taxesTier;
        transferTaxesTier = taxesTier;
        checkAndUpdateTaxes(true, true, true);
    }

    function etxBuy(uint8 taxesTier) public onlyOwner{
        require(taxesTier > 0 && taxesTier <=2);
        buyTaxesTier = taxesTier;
        checkAndUpdateTaxes(true, false, false);
    }

    function etxSell(uint8 taxesTier) public onlyOwner{
        require(taxesTier > 0 && taxesTier <=2);
        sellTaxesTier = taxesTier;
        checkAndUpdateTaxes(false, true, false);
    }

    function etxTransfer(uint8 taxesTier) public onlyOwner{
        require(taxesTier > 0 && taxesTier <=2);
        transferTaxesTier = taxesTier;
        checkAndUpdateTaxes(false, false, true);
    }

    function dtxBuy() public onlyOwner{
        buyTaxesTier = 0;
        checkAndUpdateTaxes(true, false, false);
    }

    function dtxSell() public onlyOwner{
        sellTaxesTier = 0;
        checkAndUpdateTaxes(false, true, false);
    }

    function dtxTransfer() public onlyOwner{
        transferTaxesTier = 0;
        checkAndUpdateTaxes(false, false, true);
    }

    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out self from this smart contract
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "Cannot transfer out self!");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}